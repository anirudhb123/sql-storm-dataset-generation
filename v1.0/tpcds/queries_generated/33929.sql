
WITH RECURSIVE sales_hierarchy AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ss.ss_net_profit) AS total_profit,
        COUNT(ss.ss_ticket_number) AS total_sales,
        1 AS level
    FROM customer c
    LEFT JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name
    HAVING total_profit > 1000

    UNION ALL

    SELECT 
        h.hd_demo_sk,
        CONCAT('Group ', h.hd_income_band_sk) AS c_first_name,
        NULL AS c_last_name,
        SUM(ss.ss_net_profit) AS total_profit,
        COUNT(ss.ss_ticket_number) AS total_sales,
        level + 1
    FROM household_demographics h
    LEFT JOIN store_sales ss ON h.hd_demo_sk = ss.ss_hdemo_sk
    GROUP BY h.hd_demo_sk, h.hd_income_band_sk, level
    HAVING total_profit > 500
)
SELECT 
    s.c_first_name AS customer_name,
    s.total_profit,
    s.total_sales,
    COALESCE(ROUND(s.total_profit / NULLIF(s.total_sales, 0), 2), 0) AS avg_profit_per_sale,
    d.d_year,
    d.d_month_seq,
    WT.w_warehouse_name,
    ROW_NUMBER() OVER (PARTITION BY d.d_year ORDER BY s.total_profit DESC) AS rank_within_year
FROM sales_hierarchy s
JOIN date_dim d ON d.d_date_sk = (SELECT MAX(d_date_sk) FROM date_dim)
JOIN warehouse WT ON WT.w_warehouse_sk = (SELECT MAX(w_warehouse_sk) FROM warehouse)
WHERE s.total_sales > 0
ORDER BY s.total_profit DESC
LIMIT 1000;
