
WITH RECURSIVE sales_hierarchy AS (
    SELECT s_store_sk, s_store_name, 0 AS level
    FROM store
    WHERE s_division_id = 1
    UNION ALL
    SELECT s.s_store_sk, s.s_store_name, sh.level + 1
    FROM sales_hierarchy sh
    JOIN store s ON s.s_division_id = sh.s_store_sk
),
sales_summary AS (
    SELECT 
        s.ss_store_sk,
        SUM(s.ss_sales_price) AS total_sales,
        COUNT(s.ss_ticket_number) AS total_transactions,
        RANK() OVER (PARTITION BY s.ss_store_sk ORDER BY SUM(s.ss_sales_price) DESC) AS sales_rank
    FROM store_sales s
    WHERE s.ss_sold_date_sk >= (SELECT MAX(d.d_date_sk) - 30 FROM date_dim d)
    GROUP BY s.ss_store_sk
),
detailed_sales AS (
    SELECT
        s.ss_store_sk,
        s.ss_ticket_number,
        SUM(s.ss_sales_price) AS sales_price,
        COUNT(DISTINCT s.ss_customer_sk) AS customer_count,
        COALESCE(SUM(sr.sr_return_amt), 0) AS total_returns
    FROM store_sales s
    LEFT JOIN store_returns sr ON s.ss_ticket_number = sr.sr_ticket_number AND s.ss_store_sk = sr.sr_store_sk
    GROUP BY s.ss_store_sk, s.ss_ticket_number
),
combined_sales AS (
    SELECT 
        h.s_store_name,
        COALESCE(ss.total_sales, 0) AS total_sales,
        COALESCE(ss.total_transactions, 0) AS total_transactions,
        COALESCE(ds.customer_count, 0) AS customer_count,
        COALESCE(ds.total_returns, 0) AS total_returns,
        ds.sales_price,
        (COALESCE(ds.sales_price, 0) - COALESCE(ds.total_returns, 0)) AS net_sales,
        ss.sales_rank
    FROM sales_hierarchy h
    LEFT JOIN sales_summary ss ON h.s_store_sk = ss.ss_store_sk
    LEFT JOIN detailed_sales ds ON h.s_store_sk = ds.ss_store_sk
)
SELECT 
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    cs.total_sales,
    cs.total_transactions,
    cs.customer_count,
    cs.total_returns,
    cs.net_sales,
    cs.sales_rank
FROM customer c
JOIN combined_sales cs ON cs.total_transactions > 0
WHERE c.c_birth_year BETWEEN 1980 AND 2000
AND (c.c_preferred_cust_flag = 'Y' OR c.c_email_address IS NOT NULL)
ORDER BY cs.total_sales DESC
FETCH FIRST 100 ROWS ONLY;
