
WITH RECURSIVE customer_hierarchy AS (
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, 1 AS level
    FROM customer c
    WHERE c.c_birth_year > 1990
    UNION ALL
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, ch.level + 1
    FROM customer c
    JOIN customer_hierarchy ch ON c.c_current_cdemo_sk = ch.c_customer_sk
    WHERE ch.level < 5
),
sales_summary AS (
    SELECT 
        ws.ws_bill_customer_sk AS customer_sk,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        AVG(ws.ws_list_price) AS avg_item_price
    FROM web_sales ws
    WHERE ws.ws_sold_date_sk IN (
        SELECT d.d_date_sk
        FROM date_dim d
        WHERE d.d_year = 2023 AND d.d_month_seq IN (1, 2, 3)
    )
    GROUP BY ws.ws_bill_customer_sk
),
customer_sales AS (
    SELECT 
        ch.c_customer_sk,
        ch.c_first_name,
        ch.c_last_name,
        COALESCE(ss.total_sales, 0) AS total_sales,
        COALESCE(ss.order_count, 0) AS order_count,
        RANK() OVER (ORDER BY COALESCE(ss.total_sales, 0) DESC) AS sales_rank
    FROM customer_hierarchy ch
    LEFT JOIN sales_summary ss ON ch.c_customer_sk = ss.customer_sk
)
SELECT 
    c.c_first_name,
    c.c_last_name,
    cs.total_sales,
    cs.order_count,
    CASE 
        WHEN cs.sales_rank <= 10 THEN 'Top Customer'
        WHEN cs.sales_rank <= 50 THEN 'Mid Tier Customer'
        ELSE 'Low Tier Customer'
    END AS customer_tier
FROM customer_sales cs
JOIN customer c ON cs.c_customer_sk = c.c_customer_sk
WHERE cs.total_sales > (
    SELECT AVG(total_sales)
    FROM sales_summary
)
ORDER BY cs.total_sales DESC, c.c_last_name ASC
LIMIT 100;
