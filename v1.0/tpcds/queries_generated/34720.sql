
WITH RECURSIVE customer_hierarchy AS (
    SELECT c_customer_sk, c_customer_id, c_first_name, c_last_name, c_current_cdemo_sk, 1 AS level
    FROM customer
    WHERE c_current_cdemo_sk IS NOT NULL
    UNION ALL
    SELECT c.c_customer_sk, c.c_customer_id, c.c_first_name, c.c_last_name, c.c.c_current_cdemo_sk, ch.level + 1
    FROM customer c
    JOIN customer_hierarchy ch ON c.c_current_cdemo_sk = ch.c_current_cdemo_sk
),
sales_summary AS (
    SELECT
        w.w_warehouse_id,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        AVG(ws.ws_net_profit) AS avg_net_profit
    FROM web_sales ws
    JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    WHERE ws.ws_sold_date_sk IN (
        SELECT d.d_date_sk
        FROM date_dim d
        WHERE d.d_year = 2023 AND d.d_month_seq BETWEEN 1 AND 6
    )
    GROUP BY w.w_warehouse_id
),
customer_demo AS (
    SELECT
        cd.cd_demo_sk,
        COUNT(DISTINCT c.c_customer_id) AS customer_count,
        SUM(CASE WHEN cd.cd_gender = 'M' THEN 1 ELSE 0 END) AS male_count,
        SUM(CASE WHEN cd.cd_gender = 'F' THEN 1 ELSE 0 END) AS female_count
    FROM customer_demographics cd
    LEFT JOIN customer c ON cd.cd_demo_sk = c.c_current_cdemo_sk
    GROUP BY cd.cd_demo_sk
)
SELECT 
    ch.c_customer_id,
    ch.c_first_name,
    ch.c_last_name,
    cs.customer_count,
    cs.male_count,
    cs.female_count,
    ss.total_quantity,
    ss.total_sales,
    ss.avg_net_profit,
    COALESCE(ss.total_sales, 0) - COALESCE(cd.cd_purchase_estimate, 0) AS profit_loss
FROM customer_hierarchy ch
LEFT JOIN customer_demo cs ON ch.c_current_cdemo_sk = cs.cd_demo_sk
LEFT JOIN sales_summary ss ON ss.w_warehouse_id = 
    (SELECT w.w_warehouse_id
     FROM warehouse w
     ORDER BY w.w_warehouse_sq_ft DESC
     LIMIT 1)
ORDER BY profit_loss DESC;
