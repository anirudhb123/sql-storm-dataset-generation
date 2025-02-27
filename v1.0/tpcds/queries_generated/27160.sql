
WITH customer_info AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        c.c_email_address,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        ca.ca_city,
        ca.ca_state,
        ca.ca_country
    FROM
        customer c
    JOIN
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
sales_data AS (
    SELECT
        ws.ws_ship_date_sk,
        ws.ws_item_sk,
        ws.ws_sales_price,
        ws.ws_quantity,
        ws.ws_net_profit
    FROM
        web_sales ws
),
sales_summary AS (
    SELECT
        s.c_customer_sk,
        SUM(sd.ws_sales_price * sd.ws_quantity) AS total_sales,
        SUM(sd.ws_net_profit) AS total_profit
    FROM
        customer_info s
    JOIN
        sales_data sd ON s.c_customer_sk = sd.ws_bill_customer_sk
    GROUP BY
        s.c_customer_sk
),
benchmark AS (
    SELECT
        ci.c_first_name,
        ci.c_last_name,
        ci.c_email_address,
        ci.ca_city,
        ci.ca_state,
        ci.ca_country,
        ss.total_sales,
        ss.total_profit,
        LENGTH(ci.c_email_address) AS email_length,
        TRIM(CONCAT(ci.c_first_name, ' ', ci.c_last_name)) AS full_name
    FROM
        customer_info ci
    JOIN
        sales_summary ss ON ci.c_customer_sk = ss.c_customer_sk
    WHERE
        ci.ca_state = 'CA' AND ss.total_sales > 1000
)
SELECT
    full_name,
    email_length,
    total_sales,
    total_profit
FROM
    benchmark
ORDER BY
    total_profit DESC,
    email_length ASC
LIMIT 50;
