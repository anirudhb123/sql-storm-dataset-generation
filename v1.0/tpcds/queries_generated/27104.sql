
WITH processed_addresses AS (
    SELECT
        ca_address_sk,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        TRIM(CONCAT(ca_city, ', ', ca_state, ' ', ca_zip)) AS city_state_zip
    FROM
        customer_address
),
filtered_customers AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_age_group,
        d.d_year,
        d.d_month_seq,
        d.d_day_name
    FROM
        customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN date_dim d ON c.c_first_sales_date_sk = d.d_date_sk
    WHERE
        cd.cd_gender = 'M' 
        AND cd.cd_marital_status = 'S'
),
sales_summary AS (
    SELECT
        ws_bill_customer_sk,
        COUNT(ws_order_number) AS total_orders,
        SUM(ws_net_paid) AS total_net_paid,
        AVG(ws_sales_price) AS avg_sales_price
    FROM
        web_sales
    GROUP BY
        ws_bill_customer_sk
)
SELECT
    fa.c_customer_sk,
    fa.c_first_name,
    fa.c_last_name,
    pa.full_address,
    ss.total_orders,
    ss.total_net_paid,
    ss.avg_sales_price
FROM
    filtered_customers fa
JOIN processed_addresses pa ON fa.c_customer_sk = pa.ca_address_sk
LEFT JOIN sales_summary ss ON fa.c_customer_sk = ss.ws_bill_customer_sk
WHERE
    ss.total_net_paid > 1000
ORDER BY
    fa.c_last_name,
    fa.c_first_name;
