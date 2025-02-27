
WITH customer_sales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        COALESCE(SUM(ws.ws_ext_sales_price), 0) AS total_web_sales,
        COALESCE(SUM(cs.cs_ext_sales_price), 0) AS total_catalog_sales,
        COALESCE(SUM(ss.ss_ext_sales_price), 0) AS total_store_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_web_orders,
        COUNT(DISTINCT cs.cs_order_number) AS total_catalog_orders,
        COUNT(DISTINCT ss.ss_ticket_number) AS total_store_orders
    FROM customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN catalog_sales cs ON c.c_customer_sk = cs.cs_bill_customer_sk
    LEFT JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name
),
ranked_sales AS (
    SELECT 
        c.*,
        RANK() OVER (ORDER BY total_web_sales DESC) AS web_sales_rank,
        RANK() OVER (ORDER BY total_catalog_sales DESC) AS catalog_sales_rank,
        RANK() OVER (ORDER BY total_store_sales DESC) AS store_sales_rank
    FROM customer_sales c
),
income_summary AS (
    SELECT 
        hd.hd_income_band_sk,
        AVG(ws.ws_net_profit) AS avg_web_profit,
        AVG(cs.cs_net_profit) AS avg_catalog_profit,
        AVG(ss.ss_net_profit) AS avg_store_profit
    FROM household_demographics hd
    LEFT JOIN web_sales ws ON hd.hd_demo_sk = ws.ws_bill_customer_sk
    LEFT JOIN catalog_sales cs ON hd.hd_demo_sk = cs.cs_bill_customer_sk
    LEFT JOIN store_sales ss ON hd.hd_demo_sk = ss.ss_customer_sk
    GROUP BY hd.hd_income_band_sk
)
SELECT 
    r.c_first_name,
    r.c_last_name,
    r.total_web_sales,
    r.total_catalog_sales,
    r.total_store_sales,
    r.web_sales_rank,
    r.catalog_sales_rank,
    r.store_sales_rank,
    i.avg_web_profit,
    i.avg_catalog_profit,
    i.avg_store_profit
FROM ranked_sales r
JOIN income_summary i ON i.hd_income_band_sk = (
    SELECT hd.hd_income_band_sk
    FROM household_demographics hd
    WHERE hd.hd_demo_sk = r.c_customer_sk
)
WHERE r.total_web_sales > 1000
OR (r.total_catalog_sales > 500 AND r.total_store_sales IS NULL)
ORDER BY r.web_sales_rank, r.catalog_sales_rank, r.store_sales_rank
FETCH FIRST 50 ROWS ONLY;
