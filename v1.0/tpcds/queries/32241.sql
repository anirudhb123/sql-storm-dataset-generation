
WITH RECURSIVE customer_hierarchy AS (
    SELECT
        c_customer_sk,
        c_first_name,
        c_last_name,
        c_birth_country,
        0 AS level
    FROM
        customer
    WHERE
        c_birth_country IS NOT NULL
    UNION ALL
    SELECT
        ch.c_customer_sk,
        ch.c_first_name,
        ch.c_last_name,
        ch.c_birth_country,
        ch.level + 1
    FROM
        customer_hierarchy ch
    JOIN customer c ON c.c_current_addr_sk = ch.c_customer_sk
),
sales_summary AS (
    SELECT
        ws_bill_customer_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(ws_order_number) AS total_orders,
        MAX(ws_sold_date_sk) AS last_purchase_date
    FROM
        web_sales
    WHERE
        ws_sold_date_sk > (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2022)
    GROUP BY
        ws_bill_customer_sk
),
address_info AS (
    SELECT
        ca_address_sk,
        CONCAT(ca_street_number, ' ', ca_street_name, ', ', ca_city, ', ', ca_state, ' ', ca_zip) AS full_address
    FROM
        customer_address
)
SELECT
    ch.c_customer_sk,
    ch.c_first_name,
    ch.c_last_name,
    ch.c_birth_country,
    ss.total_sales,
    ss.total_orders,
    aa.full_address,
    DENSE_RANK() OVER (PARTITION BY ch.c_birth_country ORDER BY ss.total_sales DESC) AS sales_rank
FROM
    customer_hierarchy ch
LEFT JOIN
    sales_summary ss ON ch.c_customer_sk = ss.ws_bill_customer_sk
LEFT JOIN
    address_info aa ON ch.c_customer_sk = aa.ca_address_sk
WHERE
    ss.total_sales > 1000 OR ss.total_orders > 5
ORDER BY
    ch.c_birth_country,
    sales_rank;
