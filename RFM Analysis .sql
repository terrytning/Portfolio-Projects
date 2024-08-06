-- What is the total sales amount for each year? How does it compare across different years?
SELECT Year, SUM(Amount) as Yearly_Total 
FROM SalesRFM 
GROUP BY Year 
ORDER BY Yearly_Total DESC 
-- The yearly total for 2003, 2004, 2005 are 3.5M, 4.7M, 1.7M respectively

-- Which products have the highest total quantity sold? 
SELECT Product, SUM(Quantity) as Quantity_Sold 
FROM SalesRFM 
GROUP BY Product 
ORDER BY Quantity_Sold DESC
-- Classic cars have the most quantity sold with a total of 33992

-- What is the distribution of order statuses (e.g., completed, pending, canceled)? How does it vary by country and city?
SELECT Country, City, Status, COUNT(OrderID) AS Total_Orders 
FROM SalesRFM 
GROUP BY Country, City, Status 
ORDER BY Country, City, Status
-- Based on the output we can see that the majority of the statuses are shipped 

-- How do sales amounts fluctuate across different quarters? 
SELECT Year, Quarter, SUM(Amount) as Total_Sales 
FROM SalesRFM 
GROUP BY Year, Quarter 
ORDER BY Year, Quarter
-- Based on results, the 4th quarter is consistently bringing in more sales than any other quarter

-- How does the unit price of products affect the quantity ordered? 
SELECT UnitPrice, AVG(Quantity) as Avg_Quantity 
FROM SalesRFM 
GROUP BY UnitPrice 
ORDER BY UnitPrice DESC, Avg_Quantity DESC
-- The average quantity ordered seems to vary randomly based on the unit price so we can assume the unit price does not affect
-- the amount of orders

-- Which cities and countries have the highest sales amounts?
SELECT Country, City, SUM(Amount) as Total_Sales 
FROM SalesRFM 
GROUP BY Country, City 
ORDER BY Total_Sales DESC
-- The city with the highest total sales is Madrid

SELECT Country, SUM(Amount) as Total_Sales 
FROM SalesRFM 
GROUP BY Country 
ORDER BY Total_Sales DESC
-- The country with the highest total sales is USA

-- How does the deal size (e.g., small, medium, large) impact the total sales amount and quantity ordered?
SELECT DealSize, SUM(Amount) AS Total_Sales, SUM(Quantity) AS Total_Quantity 
FROM SalesRFM 
GROUP BY DealSize 
ORDER BY DealSize
-- The medium size the most quantity sold which in turn has the highest total sales

-- What are the monthly sales trends for each year? 
SELECT Year, Month, SUM(Amount) AS Total_Sales 
FROM SalesRFM 
GROUP BY Year, Month 
ORDER BY Year, Month
-- During the first year, there is an overall steady increase in sales until the last month where there is a significant drop in sales. In the
-- next year, the sales start to dip in the first quarter but quickly begins increasing until the 11th month where again there is a significant
-- drop in sales. During the final year, the sales stay relatively consistent until the 4th month where there is a drop but qiuickly increases 
-- the next month

-- Which product codes generate the highest revenue? 
SELECT ProductCode, SUM(Amount) AS Total_Revenue 
FROM SalesRFM 
GROUP BY ProductCode 
ORDER BY Total_Revenue DESC
-- Product code S18_3232 has the highest revenue of 288245 which we saw early was classic cars that had the highest quantity sold as well

-- What products are most often sold together
SELECT p1.Product AS Product1, p2.Product AS Product2, COUNT(*) AS Frequency
FROM salesRFM p1
JOIN salesRFM p2 ON p1.OrderID = p2.OrderID AND p1.Product < p2.Product
GROUP BY p1.Product, p2.Product
ORDER BY Frequency DESC
-- The two most common products sold together are classic cars and vintage cars which has a frequency of 1247

-- What is the best product in each country
SELECT Country, Product, Quantity_Sold
FROM (
    SELECT Country, Product, SUM(Quantity) AS Quantity_Sold, ROW_NUMBER() OVER (PARTITION BY Country ORDER BY SUM(Quantity) DESC) AS Row_Num
    FROM salesRFM
    GROUP BY Country, Product
) AS RankedProducts
WHERE Row_Num = 1
ORDER BY Country
-- The output shows the highest sold product per country

-- Find the most recent order of each customer
SELECT Customer, MAX(OrderDate) as Recent_Order FROM salesRFM GROUP BY Customer ORDER BY Recent_Order DESC

-- Find the frequency of orders of each customer
SELECT Customer, COUNT(OrderID) as Total_Orders FROM salesRFM GROUP BY Customer ORDER BY Total_Orders DESC

-- Find the total spent by each customer
SELECT Customer, SUM(Amount) as Total_Amount FROM salesRFM GROUP BY Customer ORDER BY Total_Amount DESC

-- Create a sub table to include all the information above
with cte as (
	SELECT Customer, MAX(OrderDate) AS Recent_Order, COUNT(OrderID) AS Total_Orders, SUM(Amount) AS Total_Amount
	FROM salesRFM GROUP BY Customer ORDER BY Recent_Order DESC, Total_Orders DESC, Total_Amount DESC
),

-- Separate the data into 4 groups
cte2 as (
	SELECT cte.customer, 
	ntile(4) over(ORDER BY Recent_Order DESC) recency,
	ntile(4) over(ORDER BY Total_Orders DESC) frequency,
	ntile(4) over(ORDER BY Total_Amount DESC) monetary
	FROM cte ORDER BY Customer
),

-- Concatenate the 3 new columns 
cte3 as(
	SELECT *, CONCAT(recency, frequency, monetary) as RFM FROM cte2
)

-- Use case statement to determine the customer status
SELECT cte3.*,
CASE 
	WHEN cte3.RFM in ('444', '344', '434', '443', '334', '343', '433', '333', '442', '244', '424', '441',
    '233', '323', '332', '331', '133', '333')  THEN 'Lost Customer'
    WHEN cte3.RFM in ('223', '232', '322', '133', '331', '221', '422') THEN 'Slipping Away'
	ELSE 'Returning'
END Customer_Status
FROM cte3