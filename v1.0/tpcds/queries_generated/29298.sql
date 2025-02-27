
WITH AddressDetails AS (
    SELECT 
        ca_address_sk,
        TRIM(CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type)) AS full_address,
        ca_city,
        ca_state
    FROM customer_address
),
CustomerDetails AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        d.cd_gender,
        d.cd_marital_status,
        d.cd_purchase_estimate,
        CASE WHEN d.cd_gender = 'M' THEN 'Male' ELSE 'Female' END AS gender_desc,
        d.cd_education_status,
        a.full_address,
        a.ca_city,
        a.ca_state
    FROM customer c
    JOIN customer_demographics d ON c.c_current_cdemo_sk = d.cd_demo_sk
    JOIN AddressDetails a ON c.c_current_addr_sk = a.ca_address_sk
),
SalesDetails AS (
    SELECT
        ws.bill_customer_sk,
        SUM(ws.ws_sales_price * ws.ws_quantity) AS total_sales
    FROM web_sales ws
    GROUP BY ws.bill_customer_sk
),
CombinedDetails AS (
    SELECT
        cd.full_name,
        cd.gender_desc,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        cd.cd_education_status,
        sd.total_sales,
        cd.full_address,
        cd.ca_city,
        cd.ca_state
    FROM CustomerDetails cd
    LEFT JOIN SalesDetails sd ON cd.c_customer_sk = sd.bill_customer_sk
)
SELECT
    full_name,
    gender_desc,
    cd_marital_status,
    cd_purchase_estimate,
    cd_education_status,
    COALESCE(total_sales, 0) AS total_sales,
    full_address,
    ca_city,
    ca_state
FROM CombinedDetails
WHERE total_sales > 1000
ORDER BY total_sales DESC
LIMIT 10;
