
WITH CustomerSales AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_net_paid) AS total_web_sales,
        SUM(cs.cs_net_paid) AS total_catalog_sales,
        SUM(ss.ss_net_paid) AS total_store_sales,
        COUNT(DISTINCT ws.ws_order_number) AS web_order_count,
        COUNT(DISTINCT cs.cs_order_number) AS catalog_order_count,
        COUNT(DISTINCT ss.ss_ticket_number) AS store_order_count
    FROM customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN catalog_sales cs ON c.c_customer_sk = cs.cs_bill_customer_sk
    LEFT JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    WHERE c.c_last_review_date_sk IS NOT NULL
    GROUP BY c.c_customer_id
),
SalesRankings AS (
    SELECT 
        c.c_customer_id AS customer_id,
        total_web_sales,
        total_catalog_sales,
        total_store_sales,
        RANK() OVER (ORDER BY total_web_sales DESC) AS web_sales_rank,
        RANK() OVER (ORDER BY total_catalog_sales DESC) AS catalog_sales_rank,
        RANK() OVER (ORDER BY total_store_sales DESC) AS store_sales_rank
    FROM CustomerSales c
),
IncomeBands AS (
    SELECT 
        cd.cd_demo_sk,
        ib.ib_income_band_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound
    FROM household_demographics hd
    JOIN customer_demographics cd ON hd.hd_demo_sk = cd.cd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
)
SELECT 
    s.customer_id,
    COALESCE(s.total_web_sales, 0) AS total_web_sales,
    COALESCE(s.total_catalog_sales, 0) AS total_catalog_sales,
    COALESCE(s.total_store_sales, 0) AS total_store_sales,
    s.web_sales_rank,
    s.catalog_sales_rank,
    s.store_sales_rank,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    CASE 
        WHEN s.total_web_sales IS NULL AND s.total_catalog_sales IS NULL AND s.total_store_sales IS NULL THEN 'No Sales'
        WHEN s.total_web_sales > 1000 THEN 'High Value Customer'
        ELSE 'Regular Customer'
    END AS customer_segment
FROM SalesRankings s
LEFT JOIN IncomeBands ib ON s.customer_id = (SELECT c.c_customer_id FROM customer c WHERE c.c_current_cdemo_sk = ib.cd_demo_sk LIMIT 1);
