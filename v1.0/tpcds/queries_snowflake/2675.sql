
WITH ranked_sales AS (
    SELECT
        ss_store_sk,
        SUM(ss_ext_sales_price) AS total_sales,
        DENSE_RANK() OVER (PARTITION BY ss_store_sk ORDER BY SUM(ss_ext_sales_price) DESC) AS sales_rank
    FROM
        store_sales
    GROUP BY
        ss_store_sk
),
customer_info AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_credit_rating,
        COUNT(DISTINCT s.ss_ticket_number) AS total_orders
    FROM
        customer c
    LEFT JOIN
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN
        store_sales s ON c.c_customer_sk = s.ss_customer_sk
    GROUP BY
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status, cd.cd_credit_rating
),
top_customers AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        c.cd_gender,
        c.cd_marital_status,
        c.cd_credit_rating,
        c.total_orders,
        ROW_NUMBER() OVER (ORDER BY c.total_orders DESC) AS rank
    FROM
        customer_info c
    WHERE
        c.total_orders > 0
),
store_sales_ranked AS (
    SELECT
        ss_customer_sk,
        ss_store_sk,
        ss_ext_sales_price,
        ROW_NUMBER() OVER (PARTITION BY ss_store_sk ORDER BY ss_ext_sales_price DESC) AS rn
    FROM
        store_sales
)
SELECT
    tc.c_customer_sk,
    tc.c_first_name,
    tc.c_last_name,
    tc.cd_gender,
    tc.cd_marital_status,
    tc.cd_credit_rating,
    tc.total_orders,
    rs.total_sales,
    CASE
        WHEN rs.total_sales >= 10000 THEN 'High Value'
        WHEN rs.total_sales >= 5000 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS customer_value_category
FROM
    top_customers tc
LEFT JOIN (
    SELECT
        s.ss_customer_sk,
        r.total_sales
    FROM
        store_sales_ranked s
    JOIN ranked_sales r ON s.ss_store_sk = r.ss_store_sk
    WHERE
        s.rn = 1
) rs ON tc.c_customer_sk = rs.ss_customer_sk
WHERE
    tc.rank <= 10
ORDER BY
    tc.total_orders DESC;
