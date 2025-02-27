
WITH RECURSIVE Customer_Sales_CTE AS (
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, 
           SUM(ws.ws_sales_price) AS total_sales,
           COUNT(ws.ws_order_number) AS order_count
    FROM customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    WHERE c.c_current_cdemo_sk IS NOT NULL
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name
    
    UNION ALL

    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, 
           SUM(ws.ws_sales_price + COALESCE(cs.cs_sales_price, 0)) AS total_sales,
           COUNT(ws.ws_order_number) + COUNT(cs.cs_order_number) AS order_count
    FROM customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    LEFT JOIN catalog_sales cs ON c.c_customer_sk = cs.cs_ship_customer_sk
    WHERE c.c_current_cdemo_sk IS NOT NULL
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name
),
Ranked_Customers AS (
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, 
           SUM(total_sales) AS combined_sales,
           RANK() OVER (ORDER BY SUM(total_sales) DESC) AS sales_rank
    FROM Customer_Sales_CTE c
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name
),
Final_Results AS (
    SELECT r.c_customer_sk, r.c_first_name, r.c_last_name, r.combined_sales,
           COALESCE(cd.cd_marital_status, 'Unknown') AS marital_status,
           COUNT(ws.ws_order_number) OVER (PARTITION BY r.c_customer_sk) AS total_orders,
           DENSE_RANK() OVER (PARTITION BY cd.cd_gender ORDER BY r.combined_sales DESC) AS gender_rank
    FROM Ranked_Customers r
    LEFT JOIN customer_demographics cd ON r.c_customer_sk = cd.cd_demo_sk
    LEFT JOIN web_sales ws ON r.c_customer_sk = ws.ws_ship_customer_sk
)
SELECT customer_sk, first_name, last_name, combined_sales, marital_status,
       total_orders, gender_rank
FROM Final_Results
WHERE combined_sales > (
    SELECT AVG(combined_sales)
    FROM Final_Results
) AND marital_status IS NOT NULL 
ORDER BY combined_sales DESC;
