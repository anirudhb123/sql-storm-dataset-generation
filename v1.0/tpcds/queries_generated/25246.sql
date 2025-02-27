
WITH AddressParts AS (
    SELECT
        ca_address_sk,
        TRIM(CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type)) AS full_address,
        TRIM(CONCAT(ca_city, ', ', ca_state, ' ', ca_zip)) AS city_state_zip
    FROM customer_address
),
CustomerData AS (
    SELECT
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        address.full_address,
        address.city_state_zip
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN AddressParts address ON c.c_current_addr_sk = address.ca_address_sk
),
ItemsSold AS (
    SELECT
        ws_bill_customer_sk,
        SUM(ws_quantity) AS total_quantity_sold,
        SUM(ws_net_paid) AS total_sales
    FROM web_sales
    GROUP BY ws_bill_customer_sk
),
BenchmarkData AS (
    SELECT
        cust.full_name,
        cust.cd_gender,
        cust.cd_marital_status,
        cust.cd_education_status,
        items.total_quantity_sold,
        items.total_sales
    FROM CustomerData cust
    LEFT JOIN ItemsSold items ON cust.c_customer_sk = items.ws_bill_customer_sk
)
SELECT
    cd.cd_gender,
    COUNT(*) AS customer_count,
    AVG(bd.total_quantity_sold) AS avg_quantity_sold,
    AVG(bd.total_sales) AS avg_sales,
    STRING_AGG(bd.full_name, ', ') AS customers
FROM BenchmarkData bd
JOIN customer_demographics cd ON bd.cd_gender = cd.cd_gender
GROUP BY cd.cd_gender
ORDER BY customer_count DESC;
