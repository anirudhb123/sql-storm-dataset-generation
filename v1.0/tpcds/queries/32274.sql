
WITH RECURSIVE income_brackets AS (
    SELECT ib_income_band_sk, ib_lower_bound, ib_upper_bound
    FROM income_band
    WHERE ib_lower_bound IS NOT NULL
    UNION ALL
    SELECT ib.ib_income_band_sk, ib.ib_lower_bound, ib.ib_upper_bound
    FROM income_band ib
    JOIN income_brackets ib2 ON ib.ib_income_band_sk = ib2.ib_income_band_sk + 1
),
customer_sales AS (
    SELECT
        c.c_customer_sk,
        SUM(COALESCE(ws.ws_net_profit, 0)) AS total_web_sales,
        COUNT(DISTINCT ws.ws_order_number) AS web_order_count
    FROM customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY c.c_customer_sk
),
store_sales_summary AS (
    SELECT
        c.c_customer_sk,
        SUM(COALESCE(ss.ss_net_profit, 0)) AS total_store_sales,
        COUNT(DISTINCT ss.ss_ticket_number) AS store_order_count
    FROM customer c
    LEFT JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY c.c_customer_sk
),
combined_sales AS (
    SELECT
        cs.c_customer_sk,
        cs.total_web_sales,
        cs.web_order_count,
        COALESCE(sss.total_store_sales, 0) AS total_store_sales,
        sss.store_order_count
    FROM customer_sales cs
    LEFT JOIN store_sales_summary sss ON cs.c_customer_sk = sss.c_customer_sk
),
sales_ranked AS (
    SELECT
        cs.c_customer_sk,
        cs.total_web_sales,
        cs.total_store_sales,
        RANK() OVER (ORDER BY cs.total_web_sales + cs.total_store_sales DESC) AS sales_rank
    FROM combined_sales cs
)
SELECT
    cr.c_customer_sk,
    COALESCE(cr.total_web_sales, 0) AS web_sales,
    COALESCE(cr.total_store_sales, 0) AS store_sales,
    ib.ib_income_band_sk,
    CASE
        WHEN cr.total_web_sales > 0 AND cr.total_store_sales > 0 THEN 'Both'
        WHEN cr.total_web_sales > 0 THEN 'Web Only'
        WHEN cr.total_store_sales > 0 THEN 'Store Only'
        ELSE 'No Sales'
    END AS sales_category
FROM sales_ranked cr
JOIN income_brackets ib ON (
    (cr.total_web_sales + cr.total_store_sales) BETWEEN ib.ib_lower_bound AND ib.ib_upper_bound
)
WHERE cr.sales_rank <= 10
ORDER BY cr.sales_rank;
