
WITH customer_sales AS (
    SELECT 
        c.c_customer_sk,
        c.c_customer_id,
        SUM(ws.ws_net_paid) AS total_web_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY c.c_customer_sk, c.c_customer_id
),
top_customers AS (
    SELECT
        c.customer_id,
        cs.total_web_sales,
        RANK() OVER (ORDER BY cs.total_web_sales DESC) AS sales_rank
    FROM customer_sales cs
    JOIN customer c ON cs.c_customer_sk = c.c_customer_sk
    WHERE cs.total_web_sales > 0
),
store_sales_summary AS (
    SELECT 
        ss.ss_customer_sk,
        SUM(ss.ss_net_paid) AS total_store_sales,
        COUNT(DISTINCT ss.ss_ticket_number) AS total_store_orders
    FROM store_sales ss
    GROUP BY ss.ss_customer_sk
),
combined_sales AS (
    SELECT
        tc.customer_id,
        COALESCE(cs.total_web_sales, 0) AS total_web_sales,
        COALESCE(ss.total_store_sales, 0) AS total_store_sales,
        (COALESCE(cs.total_web_sales, 0) + COALESCE(ss.total_store_sales, 0)) AS total_sales,
        tc.sales_rank
    FROM top_customers tc
    LEFT JOIN customer_sales cs ON tc.customer_id = cs.c_customer_id
    LEFT JOIN store_sales_summary ss ON cs.c_customer_sk = ss.ss_customer_sk
)
SELECT
    customer_id,
    total_web_sales,
    total_store_sales,
    total_sales,
    sales_rank,
    CASE 
        WHEN total_sales > 1000 THEN 'High'
        WHEN total_sales BETWEEN 500 AND 1000 THEN 'Medium'
        ELSE 'Low'
    END AS sales_category
FROM combined_sales
WHERE total_sales IS NOT NULL
ORDER BY total_sales DESC
LIMIT 10;
