
WITH RECURSIVE sales_hierarchy AS (
    SELECT
        s_store_sk,
        s_store_id,
        s_store_name,
        s_manager,
        1 AS level
    FROM
        store
    WHERE
        s_closed_date_sk IS NULL

    UNION ALL

    SELECT
        s.s_store_sk,
        s.s_store_id,
        s.s_store_name,
        s.s_manager,
        sh.level + 1
    FROM
        store s
    JOIN sales_hierarchy sh ON s.s_manager = sh.s_store_id
),
store_sales_summary AS (
    SELECT
        ss_store_sk,
        SUM(ss_sales_price) AS total_sales,
        AVG(ss_sales_price) AS avg_sales,
        COUNT(*) AS total_transactions
    FROM
        store_sales
    WHERE
        ss_sold_date_sk >= (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023)
        AND ss_sold_date_sk <= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY
        ss_store_sk
),
customer_transactions AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        COUNT(DISTINCT ws_order_number) AS num_orders,
        SUM(ws_sales_price) AS total_spent
    FROM
        customer c
    JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE
        c.c_birth_year > 1990
    GROUP BY
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
top_customers AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        ct.total_spent,
        DENSE_RANK() OVER (ORDER BY ct.total_spent DESC) AS rank
    FROM
        customer_transactions ct
    JOIN customer c ON ct.c_customer_sk = c.c_customer_sk
)
SELECT
    s.s_store_id,
    s.s_store_name,
    sh.level AS store_level,
    ss.total_sales,
    ss.avg_sales,
    ss.total_transactions,
    tc.c_first_name,
    tc.c_last_name,
    tc.total_spent
FROM
    store_sales_summary ss
JOIN store s ON ss.ss_store_sk = s.s_store_sk
LEFT JOIN sales_hierarchy sh ON sh.s_store_sk = s.s_store_sk
LEFT JOIN top_customers tc ON tc.total_spent > 1000
WHERE
    ss.total_sales > 50000
GROUP BY
    s.s_store_id,
    s.s_store_name,
    sh.level,
    ss.total_sales,
    ss.avg_sales,
    ss.total_transactions,
    tc.c_first_name,
    tc.c_last_name,
    tc.total_spent
ORDER BY
    ss.total_sales DESC,
    tc.total_spent DESC
LIMIT 10;
