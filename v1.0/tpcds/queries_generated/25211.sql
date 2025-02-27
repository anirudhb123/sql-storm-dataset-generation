
WITH address_details AS (
    SELECT
        ca_address_id,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        ca_city,
        ca_state,
        ca_zip,
        ca_country
    FROM
        customer_address
), customer_info AS (
    SELECT
        c.c_customer_id,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating,
        cd.cd_dep_count,
        cd.cd_dep_employed_count
    FROM
        customer c
    JOIN
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
), date_info AS (
    SELECT
        d.d_date_id,
        EXTRACT(YEAR FROM d.d_date) AS year,
        EXTRACT(MONTH FROM d.d_date) AS month,
        EXTRACT(DAY FROM d.d_date) AS day,
        d.d_day_name
    FROM
        date_dim d
), sales_data AS (
    SELECT
        ws.ws_order_number,
        ws.ws_item_sk,
        ws.ws_quantity,
        ws.ws_sales_price,
        ws.ws_net_profit,
        ad.full_address AS shipping_address,
        ci.full_name AS customer_name,
        di.year,
        di.month,
        di.day,
        di.d_day_name
    FROM
        web_sales ws
    JOIN
        address_details ad ON ws.ws_ship_addr_sk = ad.ca_address_id
    JOIN
        customer_info ci ON ws.ws_bill_customer_sk = ci.c_customer_id
    JOIN
        date_info di ON ws.ws_sold_date_sk = di.d_date_id
)
SELECT
    shipping_address,
    customer_name,
    year,
    month,
    SUM(ws_quantity) AS total_quantity_sold,
    SUM(ws_sales_price) AS total_sales,
    SUM(ws_net_profit) AS total_net_profit
FROM
    sales_data
GROUP BY
    shipping_address, customer_name, year, month
ORDER BY
    total_net_profit DESC
LIMIT 100;
