
WITH RECURSIVE sales_hierarchy AS (
    SELECT s_store_sk, s_store_name, 1 AS store_level
    FROM store
    WHERE s_closed_date_sk IS NULL
    UNION ALL
    SELECT s.s_store_sk, sh.s_store_name, sh.store_level + 1
    FROM store s
    JOIN sales_hierarchy sh ON s.s_manager = sh.s_store_sk
    WHERE s_closed_date_sk IS NULL
),
customer_sales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_sales_price * ws.ws_quantity) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY SUM(ws.ws_sales_price * ws.ws_quantity) DESC) AS sales_rank
    FROM customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name
),
top_customers AS (
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name
    FROM customer_sales c
    WHERE c.sales_rank <= 5
),
store_summary AS (
    SELECT 
        sh.s_store_name,
        COUNT(DISTINCT c.c_customer_sk) AS unique_customers,
        SUM(ws.ws_sales_price) AS total_revenue,
        AVG(ws.ws_sales_price) AS avg_order_value,
        MAX(ws.ws_sales_price) AS max_order_value
    FROM sales_hierarchy sh
    LEFT JOIN web_sales ws ON sh.s_store_sk = ws.ws_warehouse_sk
    LEFT JOIN top_customers c ON ws.ws_bill_customer_sk = c.c_customer_sk
    GROUP BY sh.s_store_name
)
SELECT 
    s.s_store_name,
    COALESCE(ss.unique_customers, 0) AS unique_customers,
    COALESCE(ss.total_revenue, 0.00) AS total_revenue,
    COALESCE(ss.avg_order_value, 0.00) AS avg_order_value,
    COALESCE(ss.max_order_value, 0.00) AS max_order_value
FROM store s
LEFT JOIN store_summary ss ON s.s_store_name = ss.s_store_name
ORDER BY total_revenue DESC;
