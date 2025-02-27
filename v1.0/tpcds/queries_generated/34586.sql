
WITH RECURSIVE sales_hierarchy AS (
    SELECT w.warehouse_sk, w.warehouse_id, 1 AS level, CAST(w.warehouse_id AS VARCHAR(255)) AS path
    FROM warehouse w
    WHERE w.warehouse_sk IN (SELECT DISTINCT sr.w_warehouse_sk FROM store_returns sr)
    
    UNION ALL
    
    SELECT sr.warehouse_sk, sr.warehouse_id, sh.level + 1, CONCAT(sh.path, ' -> ', sr.warehouse_id)
    FROM store_returns sr
    JOIN sales_hierarchy sh ON sh.warehouse_sk = sr.warehouse_sk
    WHERE sh.level < 5
),
customer_data AS (
    SELECT DISTINCT c.c_customer_sk, c.c_first_name, c.c_last_name,
           CASE 
               WHEN cd.cd_gender = 'M' THEN 'Male'
               WHEN cd.cd_gender = 'F' THEN 'Female'
               ELSE 'Other'
           END AS gender,
           cd.cd_marital_status AS marital_status
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
sales_summary AS (
    SELECT 
        ws.ws_ship_date_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_profit) AS total_profit,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        DENSE_RANK() OVER (PARTITION BY ws.ws_ship_date_sk ORDER BY SUM(ws.ws_net_profit) DESC) AS rank_profit
    FROM web_sales ws
    WHERE ws.ws_ship_date_sk >= (SELECT MIN(d.d_date_sk) FROM date_dim d WHERE d.d_year = 2023)
    GROUP BY ws.ws_ship_date_sk
),
daily_sales AS (
    SELECT ds.d_date, COALESCE(ss.total_quantity, 0) AS total_quantity,
           COALESCE(ss.total_profit, 0) AS total_profit
    FROM date_dim ds
    LEFT JOIN sales_summary ss ON ds.d_date_sk = ss.ws_ship_date_sk
)
SELECT 
    dh.d_date,
    dh.total_quantity,
    dh.total_profit,
    CASE 
        WHEN dh.total_profit = 0 THEN 'No Profit'
        WHEN dh.total_profit < 1000 THEN 'Low Profit'
        WHEN dh.total_profit BETWEEN 1000 AND 5000 THEN 'Medium Profit'
        ELSE 'High Profit'
    END AS profit_category,
    cc.c_first_name,
    cc.c_last_name,
    sh.path AS warehouse_path
FROM daily_sales dh
JOIN customer_data cc ON cc.c_customer_sk = (SELECT MIN(c.c_customer_sk) 
                                             FROM customer c 
                                             WHERE c.c_birth_year BETWEEN 1980 AND 1990)
LEFT JOIN sales_hierarchy sh ON sh.warehouse_sk IN (SELECT DISTINCT ws.ws_warehouse_sk FROM web_sales ws WHERE ws.ws_ship_date_sk = dh.d_date)
WHERE dh.total_profit > 0
ORDER BY dh.d_date DESC, dh.total_profit DESC;
