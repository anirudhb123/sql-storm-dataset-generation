
WITH RECURSIVE sales_hierarchy AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        s.ss_sold_date_sk,
        SUM(s.ss_quantity) AS total_quantity,
        SUM(s.ss_net_paid) AS total_net_paid,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY SUM(s.ss_net_paid) DESC) AS rank
    FROM
        customer c
    LEFT JOIN
        store_sales s ON c.c_customer_sk = s.ss_customer_sk
    GROUP BY
        c.c_customer_sk, c.c_first_name, c.c_last_name, s.ss_sold_date_sk
),
sales_summary AS (
    SELECT
        sh.c_customer_sk,
        sh.c_first_name,
        sh.c_last_name,
        sh.total_quantity,
        sh.total_net_paid,
        dt.d_date,
        DENSE_RANK() OVER (ORDER BY sh.total_net_paid DESC) AS customer_rank
    FROM
        sales_hierarchy sh
    JOIN
        date_dim dt ON dt.d_date_sk = sh.ss_sold_date_sk
    WHERE
        sh.rank = 1
)
SELECT
    CONCAT(ss.c_first_name, ' ', ss.c_last_name) AS full_name,
    ss.total_quantity,
    ss.total_net_paid,
    dd.d_date AS last_purchase_date,
    CASE
        WHEN ss.total_net_paid IS NULL THEN 'No Purchases'
        ELSE 'Purchases Made'
    END AS purchase_status
FROM
    sales_summary ss
JOIN
    date_dim dd ON dd.d_date = (
        SELECT MAX(d_date)
        FROM sales_summary
        WHERE c_customer_sk = ss.c_customer_sk
    )
WHERE
    ss.customer_rank <= 10
ORDER BY
    ss.total_net_paid DESC
LIMIT 10;
