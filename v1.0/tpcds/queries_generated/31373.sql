
WITH RECURSIVE sales_hierarchy AS (
    SELECT 
        s_store_sk,
        s_store_name,
        s_number_employees,
        s_floor_space,
        s_sales_price,
        1 AS level
    FROM store s
    JOIN store_sales ss ON s.s_store_sk = ss.ss_store_sk 
    WHERE s_closed_date_sk IS NULL
    UNION ALL
    SELECT 
        s_store_sk,
        s_store_name,
        s_number_employees,
        s_floor_space,
        s_sales_price,
        level + 1
    FROM store s
    JOIN sales_hierarchy sh ON s.s_manager = sh.s_store_name
),
demographics AS (
    SELECT 
        cd_gender, 
        cd_marital_status, 
        COUNT(DISTINCT c_customer_sk) AS total_customers
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY cd_gender, cd_marital_status
),
sales_summary AS (
    SELECT 
        CASE 
            WHEN ws_sales_price > 100 THEN 'High'
            WHEN ws_sales_price BETWEEN 50 AND 100 THEN 'Medium'
            ELSE 'Low'
        END AS price_category,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_profit) AS total_profit
    FROM web_sales ws
    GROUP BY price_category
),
date_summary AS (
    SELECT 
        d_year,
        COUNT(DISTINCT ws_order_number) AS total_orders
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE d.d_year IN (2020, 2021)
    GROUP BY d_year
)
SELECT 
    dh.cd_gender, 
    dh.cd_marital_status, 
    COALESCE(ds.total_orders, 0) AS orders_last_year,
    COALESCE(sh.sales_price, 0) AS store_sales_price,
    ss.price_category,
    ss.total_quantity,
    ss.total_profit
FROM demographics dh
LEFT JOIN date_summary ds ON 1 = 1
LEFT JOIN sales_hierarchy sh ON sh.s_store_sk = (SELECT MIN(s_store_sk) FROM store)
LEFT JOIN sales_summary ss ON ss.price_category = 
    (SELECT CASE 
        WHEN MAX(sh.s_floor_space) > 1000 THEN 'High'
        ELSE 'Low'
    END 
    FROM sales_hierarchy sh)
WHERE dh.total_customers > 100 
ORDER BY dh.cd_gender, dh.cd_marital_status;
