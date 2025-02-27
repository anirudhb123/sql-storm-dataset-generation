
WITH address_info AS (
    SELECT
        ca.ca_address_id,
        CONCAT(ca.ca_street_number, ' ', ca.ca_street_name, ' ', ca.ca_street_type) AS full_address,
        ca.ca_city,
        ca.ca_state,
        ca.ca_zip,
        ca.ca_country,
        STRING_AGG(DISTINCT CONCAT(cd.cd_gender, ' ', cd.cd_marital_status, ' ', cd.cd_education_status), ', ') AS demographics
    FROM
        customer_address ca
    LEFT JOIN
        customer c ON ca.ca_address_sk = c.c_current_addr_sk
    LEFT JOIN
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY
        ca.ca_address_id, ca.ca_street_number, ca.ca_street_name, ca.ca_street_type, ca.ca_city, ca.ca_state, ca.ca_zip, ca.ca_country
),
sales_data AS (
    SELECT
        ws.ws_order_number,
        ws.ws_item_sk,
        ws.ws_quantity,
        ws.ws_sales_price,
        date_dim.d_date,
        time_dim.t_hour,
        time_dim.t_minute,
        address_info.full_address,
        address_info.demographics
    FROM
        web_sales ws
    JOIN
        date_dim ON ws.ws_sold_date_sk = date_dim.d_date_sk
    JOIN
        time_dim ON ws.ws_sold_time_sk = time_dim.t_time_sk
    LEFT JOIN
        address_info ON ws.ws_bill_addr_sk = address_info.ca_address_id
)
SELECT
    d_date,
    COUNT(DISTINCT ws_order_number) AS total_orders,
    SUM(ws_quantity) AS total_quantity,
    AVG(ws_sales_price) AS average_sales_price,
    MAX(ws_sales_price) AS max_sales_price,
    MIN(ws_sales_price) AS min_sales_price,
    STRING_AGG(DISTINCT demographics, '; ') AS unique_demographics
FROM
    sales_data
GROUP BY
    d_date
ORDER BY
    d_date;
