
WITH AddressData AS (
    SELECT
        ca_address_id,
        ca_street_name,
        ca_city,
        ca_state,
        ca_country,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        LENGTH(ca_street_name) AS street_name_length
    FROM
        customer_address
),
CustomerData AS (
    SELECT
        c.c_customer_id,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        CONCAT(cd.cd_gender, '-', cd.cd_marital_status) AS gender_marital_status,
        (SELECT COUNT(*) FROM customer_demographics WHERE cd_demo_sk = c.c_current_cdemo_sk) AS demographic_count
    FROM
        customer c
    JOIN
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
SalesData AS (
    SELECT
        ws.ws_order_number,
        ws.ws_sales_price,
        ws.ws_quantity,
        SUM(ws.ws_sales_price) OVER (PARTITION BY ws.ws_order_number) AS total_sales_per_order,
        (SELECT COUNT(DISTINCT ws_item_sk) FROM web_sales WHERE ws_order_number = ws.ws_order_number) AS item_count
    FROM
        web_sales ws
)
SELECT
    ad.full_address,
    cd.full_name,
    cd.gender_marital_status,
    sd.total_sales_per_order,
    sd.item_count,
    ad.street_name_length
FROM
    AddressData ad
JOIN
    CustomerData cd ON ad.ca_address_id = cd.c_customer_id
JOIN
    SalesData sd ON sd.ws.bill_customer_sk = cd.c_customer_sk
WHERE
    ad.ca_state = 'CA' AND
    cd.cd_purchase_estimate > 1000
ORDER BY
    sd.total_sales_per_order DESC,
    ad.street_name_length ASC;
