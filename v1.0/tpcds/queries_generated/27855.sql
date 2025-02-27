
WITH AddressDetails AS (
    SELECT
        ca_address_sk,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        ca_city,
        ca_state,
        ca_zip,
        ca_country
    FROM
        customer_address
),
CustomerInfo AS (
    SELECT
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        c.c_email_address,
        d.d_date AS registration_date,
        dem.cd_gender,
        dem.cd_marital_status
    FROM
        customer c
    JOIN
        date_dim d ON c.c_first_sales_date_sk = d.d_date_sk
    JOIN
        customer_demographics dem ON c.c_current_cdemo_sk = dem.cd_demo_sk
),
SalesData AS (
    SELECT
        ws.ws_order_number,
        ws.ws_sold_date_sk,
        ws.ws_quantity,
        ws.ws_sales_price,
        ws.ws_net_profit,
        s.s_store_name,
        s.s_city,
        s.s_state
    FROM
        web_sales ws
    JOIN
        store s ON ws.ws_ship_addr_sk = s.s_address
),
Overview AS (
    SELECT
        cust.full_name,
        cust.c_email_address,
        address.full_address,
        address.ca_city,
        address.ca_state,
        address.ca_zip,
        sales.ws_order_number,
        SUM(sales.ws_quantity) AS total_quantity,
        SUM(sales.ws_net_profit) AS total_net_profit
    FROM
        CustomerInfo cust
    JOIN
        AddressDetails address ON cust.c_customer_sk = address.ca_address_sk
    LEFT JOIN
        SalesData sales ON cust.c_customer_sk = sales.ws_bill_customer_sk
    GROUP BY
        cust.full_name, cust.c_email_address, address.full_address, address.ca_city, address.ca_state, address.ca_zip, sales.ws_order_number
)
SELECT
    full_name,
    c_email_address,
    full_address,
    ca_city,
    ca_state,
    ca_zip,
    COUNT(DISTINCT ws_order_number) AS order_count,
    SUM(total_quantity) AS total_quantity_sold,
    SUM(total_net_profit) AS total_profit
FROM
    Overview
GROUP BY
    full_name, c_email_address, full_address, ca_city, ca_state, ca_zip
ORDER BY
    total_profit DESC
LIMIT 100;
