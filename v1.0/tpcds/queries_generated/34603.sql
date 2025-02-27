
WITH RECURSIVE sales_summary AS (
    SELECT 
        ss_store_sk,
        SUM(ss_sales_price) AS total_sales,
        COUNT(DISTINCT ss_ticket_number) AS total_transactions,
        ROW_NUMBER() OVER (PARTITION BY ss_store_sk ORDER BY SUM(ss_sales_price) DESC) AS store_rank
    FROM store_sales 
    GROUP BY ss_store_sk
),
customer_ranked AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY c.c_customer_sk) AS gender_rank
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
date_summary AS (
    SELECT 
        d_year,
        SUM(ws_ext_sales_price) AS total_web_sales,
        SUM(ws_net_profit) AS total_web_profit
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    GROUP BY d_year
)
SELECT 
    w.w_warehouse_id,
    w.w_warehouse_name,
    COALESCE(ss.total_sales, 0) AS total_store_sales,
    COALESCE(cs.total_sales, 0) AS total_catalog_sales,
    COALESCE(ws.total_web_sales, 0) AS total_web_sales,
    cs.total_transactions AS total_catalog_transactions,
    dr.d_year,
    dr.total_web_profit,
    cr.c_first_name || ' ' || cr.c_last_name AS customer_full_name
FROM warehouse w
LEFT JOIN sales_summary ss ON w.w_warehouse_sk = ss.ss_store_sk
LEFT JOIN (
    SELECT 
        cs_ship_mode_sk,
        SUM(cs_sales_price) AS total_sales,
        COUNT(DISTINCT cs_order_number) AS total_transactions
    FROM catalog_sales
    GROUP BY cs_ship_mode_sk
) cs ON cs.cs_ship_mode_sk = w.w_warehouse_sk
LEFT JOIN date_summary dr ON dr.d_year = (SELECT MAX(d_year) FROM date_dim)
LEFT JOIN customer_ranked cr ON cr.gender_rank = 1 -- top-ranked customer by gender
WHERE COALESCE(ss.total_sales, 0) > 100000 
OR COALESCE(cs.total_sales, 0) > 50000
ORDER BY total_store_sales DESC, cr.c_first_name;
