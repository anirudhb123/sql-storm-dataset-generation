
WITH AddressDetails AS (
    SELECT 
        ca_address_sk,
        CONCAT(ca_street_number, ' ', ca_street_name, ', ', ca_city, ', ', ca_state, ' ', ca_zip) AS full_address,
        ca_country
    FROM customer_address
),
CustomerDetails AS (
    SELECT 
        c_customer_sk,
        CONCAT(c_salutation, ' ', c_first_name, ' ', c_last_name) AS full_name,
        cd_gender,
        cd_marital_status,
        cd_birth_month,
        cd_birth_year
    FROM customer
    JOIN customer_demographics ON c_current_cdemo_sk = cd_demo_sk
),
SalesData AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_sales_price) AS total_sales
    FROM web_sales
    GROUP BY ws_bill_customer_sk
)
SELECT 
    c.full_name,
    a.full_address,
    a.ca_country,
    c.cd_gender,
    c.cd_marital_status,
    c.cd_birth_month,
    c.cd_birth_year,
    COALESCE(s.total_sales, 0) AS total_sales
FROM CustomerDetails c
JOIN AddressDetails a ON a.ca_address_sk = c.c_customer_sk
LEFT JOIN SalesData s ON s.ws_bill_customer_sk = c.c_customer_sk
WHERE c.cd_gender = 'F' AND c.cd_marital_status = 'M'
ORDER BY s.total_sales DESC, c.full_name;
