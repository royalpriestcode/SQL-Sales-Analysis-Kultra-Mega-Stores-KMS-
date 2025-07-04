CREATE DATABASE KMS

SELECT * FROM KMS 

SELECT * FROM Order_Status

--A. Data Cleaning
--Checking for missing values
SELECT
	SUM(CASE WHEN Row_ID IS NULL THEN 1 ELSE 0 END) As Null_Row_ID,
	SUM(CASE WHEN Order_ID IS NULL THEN 1 ELSE 0 END) As Null_Order_ID,
	SUM(CASE WHEN Order_Date IS NULL THEN 1 ELSE 0 END) As Null_Order_Date,
	SUM(CASE WHEN Order_Priority IS NULL THEN 1 ELSE 0 END) As Null_Order_Priority,
	SUM(CASE WHEN Order_Quantity IS NULL THEN 1 ELSE 0 END) As Null_Order_Quantity,
	SUM(CASE WHEN Sales IS NULL THEN 1 ELSE 0 END) As Null_Sales,
	SUM(CASE WHEN Discount IS NULL THEN 1 ELSE 0 END) As Null_Discount,
	SUM(CASE WHEN Ship_Mode IS NULL THEN 1 ELSE 0 END) As Null_Ship_Mode,
	SUM(CASE WHEN Profit IS NULL THEN 1 ELSE 0 END) As Null_Profit,
	SUM(CASE WHEN Unit_Price IS NULL THEN 1 ELSE 0 END) As Null_Unit_Price, --12 Nulls
	SUM(CASE WHEN Shipping_Cost IS NULL THEN 1 ELSE 0 END) As Null_Shipping_Cost,
	SUM(CASE WHEN Customer_Name IS NULL THEN 1 ELSE 0 END) As Null_Customer_Name,
	SUM(CASE WHEN Province IS NULL THEN 1 ELSE 0 END) As Null_Province,
	SUM(CASE WHEN Region IS NULL THEN 1 ELSE 0 END) As Null_Region,
	SUM(CASE WHEN Customer_Segment IS NULL THEN 1 ELSE 0 END) As Null_Customer_Segment,
	SUM(CASE WHEN Product_Category IS NULL THEN 1 ELSE 0 END) As Null_Product_Category,
	SUM(CASE WHEN Product_Sub_category IS NULL THEN 1 ELSE 0 END) As Null_Product_Sub_Category,
	SUM(CASE WHEN Product_Name IS NULL THEN 1 ELSE 0 END) As Null_Product_Name,
	SUM(CASE WHEN Product_Container IS NULL THEN 1 ELSE 0 END) As Null_product_Container,
	SUM(CASE WHEN Product_Base_margin IS NULL THEN 1 ELSE 0 END) As Null_Product_Base_Margin, --63 Nulls
	SUM(CASE WHEN Ship_Date IS NULL THEN 1 ELSE 0 END) As Null_Ship_Date
FROM KMS;

--Checking for the missing values in the table.
SELECT * FROM KMS
WHERE Unit_Price IS NULL

SELECT * FROM KMS
WHERE Product_base_Margin IS NULL

--Fixing Missing Values with the Imputation Method(Mean according to SubCategory)
SELECT 
  Product_Sub_Category,
  AVG(Unit_Price) AS Avg_Unit_Price,
  AVG(Product_Base_Margin) AS Avg_Base_Margin
FROM KMS
WHERE Unit_Price IS NOT NULL OR Product_Base_Margin IS NOT NULL
GROUP BY Product_Sub_Category;

--Backing Up Original Data
SELECT *
INTO KMS_Backup
FROM KMS
WHERE Unit_Price IS NULL OR Product_Base_Margin IS NULL;

--Update Missing Values with Average according to SubCategory
--For Unit Price
UPDATE KMS
SET Unit_Price = (
    SELECT AVG(K2.Unit_Price)
    FROM KMS K2
    WHERE K2.Product_Sub_Category = KMS.Product_Sub_Category
      AND K2.Unit_Price IS NOT NULL
)
FROM KMS
WHERE KMS.Unit_Price IS NULL;
--For Product Base Margin
UPDATE KMS
SET Product_Base_Margin =(
	SELECT AVG(K2.Product_Base_margin)
	FROM KMS K2
	WHERE K2.Product_Sub_Category = KMS.Product_Sub_Category
		AND K2.Product_Base_Margin IS NOT NULL
)
FROM KMS
WHERE KMS.Product_Base_Margin IS NULL;


--Checking For Duplicates
SELECT * FROM KMS;

WITH UniqueData AS(
	SELECT *, 
		ROW_NUMBER()OVER(PARTITION BY Order_ID, Customer_Name, Product_Name, Ship_Date, Profit
		ORDER BY Order_Date
		) AS Row_Num
	FROM KMS
)
SELECT * FROM UniqueData
WHERE Row_Num > 1;
--(There are no duplicates)


--Ensure Right Date Format
ALTER TABLE KMS
ALTER COLUMN Order_Date DATE;

ALTER TABLE KMS
ALTER COLUMN Ship_Date DATE;

--Add Necessary Columns according to objectives for analysis
SELECT DATEDIFF(DAY, Order_Date, Ship_Date) AS Delivery_Days 
FROM KMS;




--B. Data Analysis
SELECT * FROM KMS;




--CASE SCENARIO ONE 
--1. Which product category had the highest sales?
SELECT TOP 1 Product_Category, ROUND(SUM(Sales), 2) AS Total_Sales
FROM KMS
GROUP BY Product_Category
ORDER BY Total_Sales DESC;
-- Product Category 'Technology' has the highest Sales of 5984248.18


--2a. What are the Top 3 and Bottom 3 regions in terms of sales?
SELECT TOP 3 Region, SUM(Sales) AS Total_Sales
FROM KMS
GROUP BY Region
ORDER BY Total_Sales DESC;
/* The region West, Ontario and Prarie has the top sales of value
3597549.27, 3063212.48 and 2837304.61 respectively */
 -- 2b. What are the Bottom 3 regions in terms of sales
 SELECT TOP 3 Region, SUM(Sales) AS Total_Sales
FROM KMS
GROUP BY Region
ORDER BY Total_Sales ASC;
/* The region Nunavut, NorthWest Territories and Yukon has the least sales of value
116376.48, 800847.33 and 975867.38 respectively */


--3. What were the total sales of appliances in Ontario?
SELECT ROUND(SUM(Sales),2) AS SubCategory_Sales
FROM KMS
WHERE Product_Sub_Category = 'Appliances'
AND Region = 'Ontario'
-- The Total Sales for Sub-Category Appliances is 202346.84


--4. Advise the management of KMS on what to do to increase the revenue from the bottom 10 customers
SELECT TOP 10 Customer_Name, 
       SUM(Sales) AS Total_Sales,
	   COUNT(Order_ID) AS Order_Count,
       AVG(Discount) AS Avg_Discount,
	   SUM(Order_Quantity) AS TotalOrderQuantity
FROM KMS
GROUP BY Customer_Name
ORDER BY Total_Sales ASC;
/* Advice to Management:

To increase revenue from the bottom 10 customers, KMS should focus on encouraging more frequent purchases and larger order quantities. 
The analysis shows that these customers place very few orders with low volumes, which directly impacts their total sales. 
Offering personalized incentives such as loyalty points, bulk purchase discounts, or targeted promotions could help boost their buying behavior. 
Additionally, understanding their specific needs or barriers to purchasing through surveys or follow-ups may reveal insights that can help improve their engagement. 
Prioritizing relationship-building with these smaller customers could gradually move them into higher-performing segments. */


-- 5. KMS incurred the most shipping cost using which shipping method?
SELECT * FROM KMS
SELECT Ship_Mode, ROUND(SUM(Shipping_Cost),2) AS Total_Shipping_Cost
FROM KMS
GROUP BY Ship_Mode
ORDER BY Total_Shipping_Cost DESC;
-- KMS incurred the most shipping cost using the Delivery Truck Shipping Method of cost 51971.94




--CASE SCENARIO TWO
--6. Who are the most valuable customers, and what products or services do they typically purchase?
SELECT TOP 5
    Customer_Name,
    SUM(Sales) AS Total_Sales,
    COUNT(DISTINCT Order_ID) AS Number_of_Orders,
    SUM(Order_Quantity) AS Total_Items_Purchased,
    MAX(Customer_Segment) AS Segment,
    Max(Product_Sub_Category) AS Products_SubPurchased,
	MAX(Product_Name) AS Products_Purchased
FROM KMS
GROUP BY Customer_Name
ORDER BY Total_Sales DESC;
/* The top 5 most valuable Customers are Emily Phan, Deborah Brumfield,Roy Skaria,Sylvia Foulston and Grant Carroll.
and they all purchase the Telephones and Communication Services, which are TimePortP7382, V70, Zoom V. 92 USB External Faxmodem,
SouthWestern Bell FA970 Digital Answering Machine, and Xerox 213 respectively.*/


--7. Which small business customer had the highest sales?
SELECT TOP 1  Customer_Name,
	ROUND(SUM(Sales),2) AS Total_Sales
FROM KMS
WHERE Customer_Segment = 'Small Business'
GROUP BY Customer_Name
ORDER BY Total_Sales DESC
-- Dennis Kane has the highest sales of 75967.59


--8. Which Corporate Customer placed the most number of orders in 2009 – 2012?
SELECT TOP 1  Customer_Name,
	COUNT(Order_ID) AS Total_Number_of_Orders
FROM KMS
WHERE Customer_Segment = 'Corporate'
AND YEAR(Order_Date) BETWEEN 2009 AND 2012
GROUP BY Customer_Name
ORDER BY Total_Number_of_Orders DESC;
-- Adam Hart has the highest number of orders of 27


--9. Which consumer customer was the most profitable one?
SELECT TOP 1  Customer_Name,
	ROUND(SUM(Profit),2) AS Total_Profit
FROM KMS
WHERE Customer_Segment = 'Consumer'
GROUP BY Customer_Name
ORDER BY Total_Profit DESC;
-- Emily Phan was the most profit consumer Customer of Total Profit of 34005.44


--10. Which customer returned items, and what segment do they belong to?
SELECT DISTINCT K.Customer_Name, K.Customer_Segment, OS.Status
FROM KMS K
LEFT JOIN Order_Status OS
ON K.Order_ID = OS.Order_ID
WHERE OS.Status = 'Returned'
/* The customer that returned items are 419 customers 
and they are all in the Consumer, Small Business, Home Office and the Corporate Segment.*/


--11. If the delivery truck is the most economical but the slowest shipping method and Express Air is the fastest but the most expensive one,
--do you think the company appropriately spent shipping costs based on the Order Priority? Explain your answer
SELECT 
    Order_Priority,
    Ship_Mode,
    COUNT(*) AS Total_Orders,
    SUM(Shipping_Cost) AS Total_Shipping_Cost
FROM KMS
GROUP BY Order_Priority, Ship_Mode
ORDER BY Order_Priority, Ship_Mode;
/* After analyzing the shipping costs across different order priorities and shipping methods, I noticed something important. 
For critical and high-priority orders — which are supposed to be delivered fast — the company often used Delivery Truck, which is actually the slowest option.
For example, 228 critical orders and 248 high-priority orders were shipped this way.
On the other hand, Express Air, which is the fastest but also the most expensive shipping method, was used quite a lot for low-priority and even "Not Specified" orders.
This shows a mismatch between how urgent an order is and how it’s being shipped.
As a result, KMS may be spending too much on shipping for orders that aren’t urgent and possibly delaying delivery for more urgent ones.

So my recommendation would be to set up a rule in their system that automatically assigns the right shipping method based on order priority. 
That way, fast methods like Express Air are saved for critical and high-priority orders, while cheaper options like Delivery Truck can be used for less urgent ones.
This can help the company save on costs and improve delivery efficiency*/
