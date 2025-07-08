
WITH RECURSIVE sales_hierarchy AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        1 AS level,
        CAST(c.c_first_name AS VARCHAR(50)) AS path
    FROM 
        customer c
    WHERE 
        c.c_customer_sk IS NOT NULL

    UNION ALL

    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        sh.level + 1,
        CONCAT(sh.path, ' > ', c.c_first_name)
    FROM 
        customer c
    JOIN 
        sales_hierarchy sh ON sh.c_customer_sk = c.c_current_cdemo_sk
    WHERE 
        sh.level < 3
),
date_range AS (
    SELECT 
        MIN(d.d_date) AS start_date,
        MAX(d.d_date) AS end_date
    FROM 
        date_dim d
    WHERE 
        d.d_year = 2022
),
sales_data AS (
    SELECT 
        ws.ws_bill_customer_sk,
        SUM(ws.ws_net_profit) AS total_profit,
        COUNT(ws.ws_order_number) AS total_orders,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_bill_customer_sk ORDER BY SUM(ws.ws_net_profit) DESC) AS profit_rank
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_date BETWEEN (SELECT start_date FROM date_range) AND (SELECT end_date FROM date_range)
    GROUP BY 
        ws.ws_bill_customer_sk
)
SELECT 
    sh.c_first_name,
    sh.c_last_name,
    COALESCE(sd.total_profit, 0) AS total_profit,
    COALESCE(sd.total_orders, 0) AS total_orders,
    sh.level,
    sh.path
FROM 
    sales_hierarchy sh
LEFT JOIN 
    sales_data sd ON sh.c_customer_sk = sd.ws_bill_customer_sk
ORDER BY 
    sh.level, total_profit DESC;
