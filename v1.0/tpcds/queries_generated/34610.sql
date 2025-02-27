
WITH RECURSIVE sales_info AS (
    SELECT
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_sales_price * ws_quantity) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_sold_date_sk DESC) AS rn
    FROM
        web_sales
    GROUP BY
        ws_item_sk
),
customer_details AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY c.c_birth_year DESC) AS customer_rank
    FROM
        customer c
    LEFT JOIN
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
address_info AS (
    SELECT
        ca.ca_address_sk,
        ca.ca_city,
        ca.ca_state,
        COUNT(DISTINCT ca.ca_address_id) AS total_addresses
    FROM
        customer_address ca
    GROUP BY
        ca.ca_address_sk, ca.ca_city, ca.ca_state
),
daily_sales AS (
    SELECT
        d.d_date,
        SUM(s.total_sales) AS total_sales_per_day
    FROM
        date_dim d
    JOIN
        sales_info s ON d.d_date_sk = s.ws_item_sk
    GROUP BY
        d.d_date
)

SELECT
    c.c_first_name,
    c.c_last_name,
    cd.cd_gender,
    cd.cd_marital_status,
    a.ca_city,
    a.ca_state,
    ds.total_sales_per_day,
    COALESCE(ds.total_sales_per_day, 0) AS daily_sales_with_default
FROM
    customer_details cd
JOIN
    customer c ON cd.c_customer_sk = c.c_customer_sk
LEFT JOIN
    address_info a ON c.c_current_addr_sk = a.ca_address_sk
LEFT JOIN 
    daily_sales ds ON ds.d_date = CURRENT_DATE
WHERE
    c.c_birth_year IS NOT NULL
    AND (cd.cd_purchase_estimate > 0 OR cd.cd_marital_status = 'M')
ORDER BY
    total_sales_per_day DESC;
