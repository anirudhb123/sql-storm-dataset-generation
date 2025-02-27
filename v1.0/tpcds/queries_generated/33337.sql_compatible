
WITH RECURSIVE sales_hierarchy AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        1 AS level,
        NULL AS parent_customer_sk
    FROM
        customer c
    WHERE
        c.c_customer_sk IS NOT NULL
    UNION ALL
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        sh.level + 1 AS level,
        sh.c_customer_sk AS parent_customer_sk
    FROM
        customer c
    JOIN
        sales_hierarchy sh ON c.c_current_cdemo_sk = sh.c_customer_sk
),
daily_sales AS (
    SELECT
        d.d_date,
        SUM(ws.ws_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        AVG(ws.ws_sales_price) AS avg_sales_price
    FROM
        date_dim d
    JOIN
        web_sales ws ON d.d_date_sk = ws.ws_sold_date_sk
    GROUP BY
        d.d_date
),
customer_sales AS (
    SELECT
        c.c_customer_sk,
        COALESCE(SUM(ws.ws_sales_price), 0) AS customer_total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS customer_order_count
    FROM
        customer c
    LEFT JOIN
        web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    GROUP BY
        c.c_customer_sk
),
sales_summary AS (
    SELECT
        sh.c_customer_sk,
        sh.c_first_name,
        sh.c_last_name,
        cs.customer_total_sales,
        cs.customer_order_count,
        CASE
            WHEN cs.customer_total_sales > 5000 THEN 'Gold'
            WHEN cs.customer_total_sales BETWEEN 2500 AND 5000 THEN 'Silver'
            ELSE 'Bronze'
        END AS customer_tier
    FROM
        sales_hierarchy sh
    JOIN
        customer_sales cs ON sh.c_customer_sk = cs.c_customer_sk
)
SELECT
    d.d_date,
    ss.c_first_name,
    ss.c_last_name,
    ss.customer_total_sales,
    ss.customer_order_count,
    ss.customer_tier,
    ROW_NUMBER() OVER (PARTITION BY ss.customer_tier ORDER BY ss.customer_total_sales DESC) AS tier_rank
FROM
    daily_sales d
JOIN
    sales_summary ss ON d.total_sales > 5000
WHERE
    ss.customer_order_count > 5
ORDER BY
    d.d_date DESC, ss.customer_total_sales DESC;
