
WITH RECURSIVE sales_hierarchy AS (
    SELECT 
        s_store_sk,
        s_store_id,
        s_store_name,
        s_number_employees,
        s_floor_space,
        s_city,
        s_state,
        s_net_paid,
        1 as level
    FROM store

    UNION ALL

    SELECT 
        s.s_store_sk,
        s.s_store_id,
        s.s_store_name,
        s.s_number_employees,
        s.s_floor_space,
        s.s_city,
        s.s_state,
        sh.s_net_paid + COALESCE(ss.ss_net_paid, 0) as s_net_paid,
        level + 1
    FROM store s
    JOIN sales_hierarchy sh ON s.s_store_sk = sh.s_store_sk
    LEFT JOIN (
        SELECT 
            ss_store_sk, 
            SUM(ss_net_paid_inc_tax) as ss_net_paid
        FROM store_sales
        GROUP BY ss_store_sk
    ) ss ON s.s_store_sk = ss.ss_store_sk
    WHERE sh.level < 3
), sales_summary AS (
    SELECT 
        sh.s_store_id,
        sh.s_store_name,
        sh.s_city,
        sh.s_state,
        SUM(sh.s_net_paid) as total_net_paid,
        COUNT(DISTINCT sh.s_store_sk) as store_count
    FROM sales_hierarchy sh
    WHERE sh.s_net_paid IS NOT NULL
    GROUP BY sh.s_store_id, sh.s_store_name, sh.s_city, sh.s_state
), customer_info AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_marital_status,
        cd.cd_gender,
        cd.cd_purchase_estimate
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE cd.cd_marital_status = 'M' AND cd.cd_purchase_estimate > 0
), web_sales_summary AS (
    SELECT 
        w.ws_item_sk,
        SUM(w.ws_sales_price) as total_sales
    FROM web_sales w
    GROUP BY w.ws_item_sk
)
SELECT 
    ss.s_store_name,
    ss.s_city,
    ss.s_state,
    cs.c_first_name,
    cs.c_last_name,
    COALESCE(wb.total_sales, 0) AS total_web_sales,
    ss.total_net_paid,
    (ss.total_net_paid - COALESCE(wb.total_sales, 0)) AS net_profit_after_web
FROM sales_summary ss
JOIN customer_info cs ON cs.cd_purchase_estimate > 1000
LEFT JOIN web_sales_summary wb ON ss.s_store_id = wb.ws_item_sk
WHERE ss.total_net_paid > 5000
ORDER BY ss.total_net_paid DESC
LIMIT 10;
