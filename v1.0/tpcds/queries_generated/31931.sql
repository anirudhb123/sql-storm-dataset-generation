
WITH RECURSIVE date_hierarchy AS (
    SELECT d_date_sk, d_date, d_year, d_month_seq, d_week_seq, d_quarter_seq, 1 AS level
    FROM date_dim
    WHERE d_year BETWEEN 2020 AND 2023
    UNION ALL
    SELECT d.d_date_sk, d.d_date, d.d_year, d.d_month_seq, d.d_week_seq, d.d_quarter_seq, dh.level + 1
    FROM date_dim d
    INNER JOIN date_hierarchy dh ON d.d_year = dh.d_year AND d.d_month_seq = dh.d_month_seq + 1
),
customer_summary AS (
    SELECT 
        c.c_customer_sk,
        COUNT(DISTINCT cs.cs_order_number) AS total_orders,
        SUM(cs.cs_sales_price) AS total_sales
    FROM customer c
    LEFT JOIN store_sales cs ON c.c_customer_sk = cs.ss_customer_sk
    GROUP BY c.c_customer_sk
),
customer_income AS (
    SELECT 
        hd.hd_demo_sk,
        SUM(CASE WHEN hd.hd_income_band_sk IS NOT NULL THEN 1 ELSE 0 END) AS income_count
    FROM household_demographics hd
    GROUP BY hd.hd_demo_sk
),
address_with_returns AS (
    SELECT 
        ca.ca_address_sk,
        COALESCE(SUM(sr_return_quantity), 0) AS total_returns
    FROM customer_address ca
    LEFT JOIN store_returns sr ON ca.ca_address_sk = sr.sr_addr_sk
    GROUP BY ca.ca_address_sk
)
SELECT 
    dh.d_year,
    COUNT(DISTINCT c.c_customer_id) AS customer_count,
    SUM(COALESCE(cs.total_sales, 0)) AS total_sales,
    AVG(COALESCE(cs.total_orders, 0)) AS avg_orders_per_customer,
    SUM(COALESCE(ar.total_returns, 0)) AS total_returns
FROM date_hierarchy dh
LEFT JOIN customer_summary cs ON cs.c_customer_sk = cs.c_customer_sk 
LEFT JOIN customer_income ci ON ci.hd_demo_sk = cs.c_customer_sk
LEFT JOIN address_with_returns ar ON ar.ca_address_sk = cs.c_customer_sk 
WHERE dh.level = 1
AND dh.d_year IN (2020, 2021, 2022, 2023)
GROUP BY dh.d_year
ORDER BY dh.d_year;
