
WITH RECURSIVE sales_dates AS (
    SELECT d_date_sk, d_date 
    FROM date_dim 
    WHERE d_date = (SELECT MAX(d_date) FROM date_dim) 
    UNION ALL 
    SELECT d.d_date_sk, d.d_date 
    FROM date_dim d 
    JOIN sales_dates sd ON d.d_date_sk = sd.d_date_sk - 1
),

customer_sales AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS order_count,
        CASE 
            WHEN SUM(ws.ws_ext_sales_price) IS NULL THEN 'No Sales'
            ELSE 'Sales Exist'
        END AS sales_status
    FROM customer c 
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE c.c_birth_year BETWEEN 1950 AND 2000
    GROUP BY c.c_customer_id
),

store_sales_summary AS (
    SELECT 
        s.s_store_id,
        SUM(ss.ss_ext_sales_price) AS total_store_sales,
        COUNT(ss.ss_ticket_number) AS total_transactions
    FROM store s 
    LEFT JOIN store_sales ss ON s.s_store_sk = ss.ss_store_sk
    GROUP BY s.s_store_id
),

SalesInfo AS (
    SELECT 
        cs.c_customer_id,
        COALESCE(cs.total_sales, 0) AS total_sales,
        cs.order_count,
        COALESCE(ss.total_store_sales, 0) AS total_store_sales,
        ss.total_transactions,
        d.d_date
    FROM customer_sales cs 
    FULL OUTER JOIN store_sales_summary ss ON cs.total_sales > 0 AND ss.total_store_sales > 0
    CROSS JOIN sales_dates d
)

SELECT 
    c.customer_id,
    s.store_id,
    SUM(s.sales) AS total_sales,
    AVG(s.total_store_sales) AS avg_store_sales,
    MAX(s.order_count) AS max_orders,
    COUNT(s.store_id) AS store_count,
    DENSE_RANK() OVER (PARTITION BY s.store_id ORDER BY SUM(s.sales) DESC) AS sales_rank
FROM SalesInfo s 
JOIN customer c ON c.c_customer_id = s.customer_id
WHERE s.total_sales > 0 OR s.total_store_sales > 0
GROUP BY c.customer_id, s.store_id
HAVING AVG(s.total_store_sales) > 1000
ORDER BY total_sales DESC, store_id;
