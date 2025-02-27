
WITH AddressDetails AS (
    SELECT
        ca_address_sk,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type, 
               CASE WHEN ca_suite_number IS NOT NULL THEN CONCAT(' Suite ', ca_suite_number) ELSE '' END) AS full_address,
        ca_city,
        ca_state,
        ca_zip
    FROM
        customer_address
), CustomerDetails AS (
    SELECT
        c_customer_sk,
        CONCAT(c_first_name, ' ', c_last_name) AS full_name,
        cd_demo_sk,
        cd_gender,
        cd_marital_status
    FROM
        customer c
    JOIN
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
), SalesData AS (
    SELECT
        ws.web_site_id,
        ws.ws_order_number,
        ws.ws_sales_price,
        ca.zip AS customer_zip,
        cd.gender AS customer_gender,
        cd.marital_status AS customer_marital_status,
        ROW_NUMBER() OVER (PARTITION BY ws.web_site_id ORDER BY ws.ws_sales_price DESC) AS rn
    FROM
        web_sales ws
    JOIN
        CustomerDetails cd ON ws.ws_bill_customer_sk = cd.c_customer_sk
    JOIN
        AddressDetails ca ON ws.ws_bill_addr_sk = ca.ca_address_sk
)
SELECT
    sd.web_site_id,
    COUNT(sd.ws_order_number) AS total_orders,
    AVG(sd.ws_sales_price) AS average_sales_price,
    SUM(sd.ws_sales_price) AS total_sales_value,
    MAX(sd.ws_sales_price) AS max_single_sale
FROM
    SalesData sd
WHERE
    sd.rn <= 10
GROUP BY
    sd.web_site_id
ORDER BY
    total_sales_value DESC;
