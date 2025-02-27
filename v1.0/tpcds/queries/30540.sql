
WITH RECURSIVE sales_summary AS (
    SELECT
        ws_bill_customer_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_ext_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws_bill_customer_sk ORDER BY SUM(ws_ext_sales_price) DESC) AS rn
    FROM
        web_sales
    GROUP BY
        ws_bill_customer_sk
),
top_customers AS (
    SELECT
        c.c_customer_id,
        s.total_quantity,
        s.total_sales,
        d.d_year
    FROM
        customer c
    JOIN
        sales_summary s ON c.c_customer_sk = s.ws_bill_customer_sk
    JOIN
        date_dim d ON d.d_date_sk = (
            SELECT MAX(ws_sold_date_sk)
            FROM web_sales
            WHERE ws_bill_customer_sk = s.ws_bill_customer_sk
        )
    WHERE
        s.rn <= 10
),
average_sales AS (
    SELECT
        AVG(total_sales) AS avg_sales
    FROM
        top_customers
),
customer_addresses AS (
    SELECT
        ca.ca_address_id,
        ca.ca_city,
        ca.ca_state,
        ca.ca_country
    FROM
        customer_address ca
    LEFT JOIN
        customer c ON ca.ca_address_sk = c.c_current_addr_sk
)
SELECT
    COALESCE(cu.c_customer_id, 'Unknown Customer') AS customer_id,
    cu.total_quantity AS quantity_purchased,
    cu.total_sales AS total_spent,
    ca.ca_city,
    ca.ca_state,
    ca.ca_country,
    a.avg_sales
FROM
    top_customers cu
LEFT JOIN
    customer_addresses ca ON ca.ca_address_id = cu.c_customer_id
CROSS JOIN
    average_sales a
WHERE
    cu.total_sales > a.avg_sales
ORDER BY
    cu.total_sales DESC;
