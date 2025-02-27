
WITH RECURSIVE Customer_Hierarchy AS (
    SELECT c_customer_sk, c_first_name, c_last_name, c_current_cdemo_sk,
           0 AS level
    FROM customer
    WHERE c_customer_sk IS NOT NULL
    UNION ALL
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, c.c_current_cdemo_sk,
           ch.level + 1
    FROM customer c
    JOIN Customer_Hierarchy ch ON c.c_current_cdemo_sk = ch.c_current_cdemo_sk
    WHERE ch.level < 3
),
Sales_Data AS (
    SELECT 
        ws.ws_sold_date_sk,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        SUM(ws.ws_quantity) AS total_quantity,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM web_sales ws
    JOIN date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE dd.d_year = 2023
    GROUP BY ws.ws_sold_date_sk
),
Customer_Sales AS (
    SELECT 
        ch.c_customer_sk,
        SUM(sd.total_sales) AS customer_total_sales,
        COUNT(DISTINCT sd.total_orders) AS customer_order_count
    FROM Customer_Hierarchy ch
    LEFT JOIN Sales_Data sd ON ch.c_customer_sk = sd.ws_bill_customer_sk
    GROUP BY ch.c_customer_sk
)
SELECT 
    ca.ca_city,
    COUNT(DISTINCT cs.c_customer_sk) AS unique_customers,
    SUM(cs.customer_total_sales) AS total_revenue,
    AVG(cs.customer_order_count) AS avg_orders_per_customer,
    RANK() OVER (ORDER BY SUM(cs.customer_total_sales) DESC) AS revenue_rank
FROM customer_address ca
JOIN customer c ON ca.ca_address_sk = c.c_current_addr_sk
JOIN Customer_Sales cs ON cs.c_customer_sk = c.c_customer_sk
WHERE ca.ca_city IS NOT NULL
GROUP BY ca.ca_city
HAVING SUM(cs.customer_total_sales) > 1000.00
ORDER BY revenue_rank
```
