
WITH RECURSIVE sales_hierarchy AS (
    SELECT s_store_sk, s_store_name, NULL::integer AS parent_store_sk, 0 AS level
    FROM store
    WHERE s_country = 'USA'
    UNION ALL
    SELECT st.s_store_sk, st.s_store_name, sh.s_store_sk AS parent_store_sk, sh.level + 1
    FROM store st
    JOIN sales_hierarchy sh ON st.s_store_sk = sh.parent_store_sk
),
customer_transactions AS (
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name,
           COALESCE(sum(ws.ws_sales_price), 0) AS total_sales,
           COUNT(DISTINCT ws.ws_order_number) AS order_count,
           ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY COALESCE(sum(ws.ws_sales_price), 0) DESC) AS sales_rank
    FROM customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name
),
top_customers AS (
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, ct.total_sales
    FROM customer c
    JOIN customer_transactions ct ON c.c_customer_sk = ct.c_customer_sk
    WHERE ct.sales_rank <= 10
),
promotion_summary AS (
    SELECT p.p_promo_id, p.p_promo_name,
           SUM(ws.ws_ext_sales_price) AS total_sales
    FROM promotion p
    LEFT JOIN web_sales ws ON p.p_promo_sk = ws.ws_promo_sk
    GROUP BY p.p_promo_id, p.p_promo_name
)
SELECT 
    ts.c_customer_sk,
    ts.c_first_name,
    ts.c_last_name,
    CASE 
        WHEN ts.total_sales > 1000 THEN 'High Value'
        WHEN ts.total_sales BETWEEN 500 AND 1000 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS customer_value_segment,
    COALESCE(ps.total_sales, 0) AS total_promotion_sales,
    ROW_NUMBER() OVER (ORDER BY ts.total_sales DESC) AS customer_rank
FROM top_customers ts
LEFT JOIN promotion_summary ps ON ts.total_sales > 0 AND ps.total_sales = (
    SELECT MAX(total_sales)
    FROM promotion_summary
    WHERE total_sales <= ts.total_sales
)
WHERE ts.c_first_name IS NOT NULL OR ts.c_last_name IS NOT NULL
ORDER BY customer_rank, ts.c_last_name, ts.c_first_name;
