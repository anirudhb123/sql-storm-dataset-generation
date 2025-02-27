
WITH customer_sales AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_net_paid) AS total_web_sales,
        SUM(cs.cs_net_paid) AS total_catalog_sales,
        SUM(ss.ss_net_paid) AS total_store_sales
    FROM customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN catalog_sales cs ON c.c_customer_sk = cs.cs_bill_customer_sk
    LEFT JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY c.c_customer_id
),
sales_summary AS (
    SELECT
        c.c_customer_id,
        COALESCE(cs.total_web_sales, 0) AS web_sales,
        COALESCE(cs.total_catalog_sales, 0) AS catalog_sales,
        COALESCE(cs.total_store_sales, 0) AS store_sales,
        (COALESCE(cs.total_web_sales, 0) + COALESCE(cs.total_catalog_sales, 0) + COALESCE(cs.total_store_sales, 0)) AS total_sales
    FROM customer_sales cs
    JOIN customer c ON cs.c_customer_id = c.c_customer_id
),
ranked_sales AS (
    SELECT
        ss.c_customer_id,
        ss.total_sales,
        RANK() OVER (ORDER BY ss.total_sales DESC) AS sales_rank
    FROM sales_summary ss
)
SELECT
    rs.c_customer_id,
    rs.total_sales,
    rs.sales_rank,
    d.d_year,
    d.d_month_seq,
    COUNT(DISTINCT ws.ws_order_number) AS total_orders,
    MAX(ws.ws_net_profit) AS max_profit
FROM ranked_sales rs
LEFT JOIN web_sales ws ON rs.c_customer_id = ws.ws_bill_customer_sk
LEFT JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
WHERE d.d_year = 2023 
  AND (ws.ws_net_paid - ws.ws_ext_discount_amt) > 50
GROUP BY rs.c_customer_id, rs.total_sales, rs.sales_rank, d.d_year, d.d_month_seq
HAVING SUM(ws.ws_net_paid) > 1000
ORDER BY rs.sales_rank
LIMIT 100;
