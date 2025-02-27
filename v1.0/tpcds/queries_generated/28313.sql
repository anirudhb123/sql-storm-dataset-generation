
WITH customer_data AS (
    SELECT
        c.c_customer_id,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        ca.ca_city,
        ca.ca_state
    FROM
        customer c
    JOIN
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
sales_data AS (
    SELECT
        ws.ws_order_number,
        ws.ws_sales_price,
        c.c_customer_id,
        c.full_name,
        d.d_date
    FROM
        web_sales ws
    INNER JOIN
        customer_data c ON ws.ws_bill_customer_sk = c.c_customer_id
    JOIN
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
),
aggregated_sales AS (
    SELECT
        full_name,
        ca_state,
        SUM(ws_sales_price) AS total_sales,
        COUNT(ws_order_number) AS order_count
    FROM
        sales_data
    GROUP BY
        full_name, ca_state
)
SELECT
    total_sales,
    SUM(order_count) OVER (PARTITION BY ca_state) AS total_orders_by_state,
    RANK() OVER (PARTITION BY ca_state ORDER BY total_sales DESC) AS sales_rank
FROM
    aggregated_sales
WHERE
    total_sales > 500
ORDER BY
    ca_state, sales_rank;
