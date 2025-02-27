
WITH RECURSIVE sales_hierarchy AS (
    SELECT 
        c.customer_sk,
        c.first_name,
        c.last_name,
        1 AS level,
        CAST(c.first_name AS VARCHAR(100)) AS path
    FROM customer c
    WHERE c.first_shipto_date_sk IS NOT NULL

    UNION ALL

    SELECT 
        c.customer_sk,
        c.first_name,
        c.last_name,
        sh.level + 1,
        CAST(CONCAT(sh.path, ' -> ', c.first_name) AS VARCHAR(100))
    FROM customer c
    JOIN sales_hierarchy sh ON c.current_hdemo_sk = sh.customer_sk
    WHERE sh.level < 5
),

sales_summary AS (
    SELECT 
        c.c_customer_id,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_net_paid_inc_tax) AS total_sales,
        AVG(ws.ws_net_profit) AS avg_profit
    FROM customer c
    JOIN web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    GROUP BY c.c_customer_id
),

daily_sales AS (
    SELECT 
        dd.d_date,
        SUM(ws.ws_sales_price) AS total_sales,
        SUM(ws.ws_net_profit) AS total_profit
    FROM web_sales ws
    JOIN date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    GROUP BY dd.d_date
)

SELECT 
    sh.first_name,
    sh.last_name,
    sh.level,
    ss.total_orders,
    ss.total_sales,
    ss.avg_profit,
    ds.total_sales AS daily_sales,
    ds.total_profit AS daily_profit
FROM sales_hierarchy sh
LEFT JOIN sales_summary ss ON sh.customer_sk = ss.c_customer_id
FULL OUTER JOIN daily_sales ds ON ds.total_sales > 0
WHERE (ss.total_sales > 1000 OR ds.total_profit > 500)
ORDER BY sh.level, ss.total_sales DESC, ds.total_profit DESC;
