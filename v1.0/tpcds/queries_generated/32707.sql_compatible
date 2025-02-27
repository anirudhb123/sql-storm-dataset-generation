
WITH RECURSIVE sales_hierarchy AS (
    SELECT 
        s_store_sk,
        s_store_name,
        s_number_employees,
        1 AS level
    FROM store
    WHERE s_closed_date_sk IS NULL
    UNION ALL
    SELECT 
        s.s_store_sk,
        s.s_store_name,
        s.s_number_employees,
        sh.level + 1
    FROM store s
    JOIN sales_hierarchy sh ON s.s_store_sk = sh.s_store_sk
),
customer_purchases AS (
    SELECT 
        c.c_customer_sk,
        COUNT(ws.ws_order_number) AS total_orders,
        SUM(ws.ws_net_profit) AS total_profit,
        MAX(ws.ws_sold_date_sk) AS last_purchase_date
    FROM customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    GROUP BY c.c_customer_sk
),
holiday_sales AS (
    SELECT 
        d.d_year,
        SUM(CASE WHEN ws.ws_sales_price IS NOT NULL THEN ws.ws_sales_price ELSE 0 END) AS holiday_sales
    FROM date_dim d
    JOIN web_sales ws ON d.d_date_sk = ws.ws_sold_date_sk
    WHERE d.d_holiday = 'Y'
    GROUP BY d.d_year
),
avg_sales AS (
    SELECT 
        c.c_customer_sk,
        AVG(s.total_profit) AS avg_profit_per_customer
    FROM customer_purchases c
    JOIN customer_purchases s ON c.total_orders = s.total_orders
    GROUP BY c.c_customer_sk
)
SELECT 
    ca.ca_city,
    COUNT(DISTINCT c.c_customer_id) AS unique_customers,
    COALESCE(SUM(ws.ws_net_profit), 0) AS total_web_sales,
    COALESCE(SUM(ss.ss_net_profit), 0) AS total_store_sales,
    COALESCE(AVG(ash.avg_profit_per_customer), 0) AS average_profit,
    MAX(ds.last_purchase_date) AS recent_purchase_date
FROM customer_address ca
LEFT JOIN customer c ON c.c_current_addr_sk = ca.ca_address_sk
LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
LEFT JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
LEFT JOIN avg_sales ash ON c.c_customer_sk = ash.c_customer_sk
LEFT JOIN customer_purchases ds ON c.c_customer_sk = ds.c_customer_sk
GROUP BY ca.ca_city
ORDER BY total_web_sales DESC
LIMIT 100;
