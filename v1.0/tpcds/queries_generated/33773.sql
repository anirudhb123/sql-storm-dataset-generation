
WITH RECURSIVE sales_trends AS (
    SELECT 
        ws_item_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_sold_date_sk DESC) AS rn
    FROM web_sales
    GROUP BY ws_item_sk
),
customer_summary AS (
    SELECT 
        c.c_customer_sk,
        COALESCE(cd.cd_gender, 'U') AS gender,
        COALESCE(hd.hd_income_band_sk, 0) AS income_band,
        COUNT(DISTINCT ws.web_site_sk) AS visited_websites
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY c.c_customer_sk, hd.hd_income_band_sk, cd.cd_gender
),
warehouse_performance AS (
    SELECT 
        w.w_warehouse_sk,
        SUM(COALESCE(ws.ws_net_profit, 0)) AS total_profit,
        COUNT(ws.ws_order_number) AS order_count
    FROM warehouse w
    LEFT JOIN web_sales ws ON w.w_warehouse_sk = ws.ws_warehouse_sk
    GROUP BY w.w_warehouse_sk
),
customer_performance AS (
    SELECT 
        cs.c_customer_sk,
        AVG(COALESCE(ws.ws_net_paid_inc_tax, 0)) AS avg_net_paid,
        SUM(ws.ws_quantity) AS total_quantity
    FROM customer_summary cs
    LEFT JOIN web_sales ws ON cs.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY cs.c_customer_sk
)
SELECT 
    c.c_customer_id,
    cs.gender,
    cs.income_band,
    wp.web_name,
    COALESCE(wp.web_rec_start_date, '1970-01-01') AS web_start_date,
    wp.web_rec_end_date AS web_end_date,
    w.w_warehouse_id,
    w.total_profit,
    w.order_count,
    COALESCE(cp.avg_net_paid, 0) AS avg_spent,
    cp.total_quantity,
    st.total_sales
FROM customer c
JOIN customer_summary cs ON c.c_customer_sk = cs.c_customer_sk
JOIN warehouse_performance w ON w.w_warehouse_sk IN (
    SELECT DISTINCT ws.ws_warehouse_sk
    FROM web_sales ws
    WHERE ws.ws_bill_customer_sk = c.c_customer_sk
)
JOIN web_page wp ON wp.wp_web_page_sk = (
    SELECT wp2.wp_web_page_sk
    FROM web_page wp2
    WHERE wp2.wp_customer_sk = c.c_customer_sk
    ORDER BY wp2.wp_access_date_sk DESC 
    LIMIT 1
)
LEFT JOIN customer_performance cp ON cp.c_customer_sk = c.c_customer_sk
LEFT JOIN sales_trends st ON st.ws_item_sk = (
    SELECT ws_item_sk
    FROM web_sales
    WHERE ws_bill_customer_sk = c.c_customer_sk
    ORDER BY ws_sold_date_sk DESC
    LIMIT 1
)
WHERE cs.visited_websites > 0
AND (cs.gender IS NOT NULL OR cs.income_band > 0)
ORDER BY avg_spent DESC, total_quantity DESC;
