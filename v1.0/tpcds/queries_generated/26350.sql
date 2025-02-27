
WITH CustomerAddressDetails AS (
    SELECT
        ca.ca_address_id,
        CONCAT(ca.ca_street_number, ' ', ca.ca_street_name, ' ', ca.ca_street_type) AS full_address,
        ca.ca_city,
        ca.ca_state,
        ca.ca_zip,
        ca.ca_country
    FROM
        customer_address ca
),
CustomerFullNames AS (
    SELECT
        c.c_customer_id,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status
    FROM
        customer c
    JOIN
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
SalesData AS (
    SELECT
        ws.ws_order_number,
        ws.ws_sold_date_sk,
        ws.ws_quantity,
        ws.ws_ext_sales_price,
        ws.ws_net_paid,
        ca.full_address,
        cfn.full_name
    FROM
        web_sales ws
    JOIN
        CustomerAddressDetails ca ON ws.ws_ship_addr_sk = ca.ca_address_id
    JOIN
        CustomerFullNames cfn ON ws.ws_bill_customer_sk = cfn.c_customer_id
),
DateDim AS (
    SELECT
        d.d_date_sk,
        d.d_month_seq,
        d.d_year,
        d.d_day_name
    FROM
        date_dim d
)
SELECT
    DATE_FORMAT(DATE_ADD(DATE(d.d_date_sk), INTERVAL 1 DAY), '%Y-%m-%d') AS next_day,
    dd.d_month_seq,
    dd.d_year,
    COUNT(sd.ws_order_number) AS total_orders,
    SUM(sd.ws_net_paid) AS total_net_paid,
    AVG(sd.ws_net_paid) AS avg_net_paid,
    MAX(sd.ws_net_paid) AS max_net_paid,
    GROUP_CONCAT(DISTINCT sd.full_address SEPARATOR '; ') AS unique_addresses,
    GROUP_CONCAT(DISTINCT sd.full_name SEPARATOR '; ') AS customer_names
FROM
    SalesData sd
JOIN
    DateDim dd ON sd.ws_sold_date_sk = dd.d_date_sk
WHERE
    sd.ws_net_paid > 0
GROUP BY
    next_day, dd.d_month_seq, dd.d_year
ORDER BY
    dd.d_year DESC, dd.d_month_seq DESC;
