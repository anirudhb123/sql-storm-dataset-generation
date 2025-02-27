
WITH RECURSIVE CustomerCTE AS (
    SELECT c_customer_sk, c_first_name, c_last_name, c_current_addr_sk, 1 AS Level
    FROM customer
    WHERE c_birth_year > 1980
    
    UNION ALL
    
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, c.c_current_addr_sk, Level + 1
    FROM customer c
    JOIN CustomerCTE recursive cte ON c.c_current_addr_sk = cte.c_current_addr_sk
    WHERE Level < 5
),
SalesData AS (
    SELECT ws_bill_customer_sk, SUM(ws_net_paid) AS Total_Sales, COUNT(ws_order_number) AS Order_Count
    FROM web_sales
    WHERE ws_sold_date_sk IN (
        SELECT d_date_sk
        FROM date_dim
        WHERE d_year = 2023 AND d_month_seq BETWEEN 1 AND 3
    )
    GROUP BY ws_bill_customer_sk
),
CustomerAggregate AS (
    SELECT cd.cd_demo_sk, 
           SUM(sd.Total_Sales) AS Customer_Sales, 
           COUNT(sd.Order_Count) AS Total_Orders,
           MAX(sd.Total_Sales) AS Max_Sale_Per_Customer
    FROM CustomerCTE cte
    LEFT JOIN customer_demographics cd ON cte.c_customer_sk = cd.cd_demo_sk
    LEFT JOIN SalesData sd ON sd.ws_bill_customer_sk = cte.c_customer_sk
    GROUP BY cd.cd_demo_sk
)
SELECT ca.ca_city,
       COUNT(DISTINCT cte.c_customer_sk) AS Total_Customers,
       AVG(ca.ca_gmt_offset) AS Avg_GMT_Offset,
       SUM(COALESCE(ca.ca_zip IS NULL, 1, 0)) AS Missing_Zip_Count,
       SUM(ca.ca_gmt_offset) / COUNT(ca.ca_city) AS Weighted_Avg_GMT
FROM customer_address ca
JOIN CustomerCTE cte ON ca.ca_address_sk = cte.c_current_addr_sk
GROUP BY ca.ca_city
HAVING COUNT(DISTINCT cte.c_customer_sk) > 10
ORDER BY Total_Customers DESC
LIMIT 10;
