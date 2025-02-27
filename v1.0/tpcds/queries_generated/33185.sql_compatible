
WITH RECURSIVE inventory_hierarchy AS (
    SELECT i_item_sk, i_current_price, 1 AS level
    FROM item
    WHERE i_item_sk IN (SELECT DISTINCT sr_item_sk FROM store_returns  
                        WHERE sr_return_quantity > 0)
    UNION ALL
    SELECT i_item_sk, i_current_price * 0.9 AS i_current_price, level + 1
    FROM inventory_hierarchy
    WHERE level < 3
),
customer_info AS (
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, 
           cd.cd_gender, cd.cd_marital_status, 
           ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY c.c_birth_year) AS rnk
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
sales_summary AS (
    SELECT 
        ws.ws_sold_date_sk, 
        SUM(ws.ws_net_paid) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_net_profit) AS total_profit
    FROM web_sales ws
    JOIN date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE dd.d_year = 2023
    GROUP BY ws.ws_sold_date_sk
)
SELECT 
    ca.ca_city, 
    SUM(ss.total_sales) AS total_sales,
    AVG(ci.c_birth_year) AS avg_birth_year,
    COUNT(DISTINCT ci.c_customer_sk) AS unique_customers
FROM customer_address ca
LEFT JOIN customer c ON c.c_current_addr_sk = ca.ca_address_sk
LEFT JOIN customer_info ci ON ci.c_customer_sk = c.c_customer_sk
LEFT JOIN sales_summary ss ON ss.ws_sold_date_sk = c.c_first_sales_date_sk 
GROUP BY ca.ca_city
HAVING SUM(ss.total_sales) > (SELECT AVG(total_sales) FROM sales_summary)
ORDER BY total_sales DESC;
