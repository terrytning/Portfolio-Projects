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

