
WITH AddressSegments AS (
    SELECT 
        ca_address_sk,
        CONCAT(TRIM(ca_street_number), ' ', TRIM(ca_street_name), ' ', TRIM(ca_street_type)) AS full_address,
        TRIM(ca_city) AS city,
        TRIM(ca_state) AS state,
        TRIM(ca_zip) AS zip
    FROM customer_address
), 
CustomerNames AS (
    SELECT 
        c_customer_sk,
        CONCAT(TRIM(c_salutation), ' ', TRIM(c_first_name), ' ', TRIM(c_last_name)) AS full_name
    FROM customer
), 
Demographics AS (
    SELECT 
        cd_demo_sk,
        cd_gender,
        cd_marital_status,
        cd_education_status,
        cd_purchase_estimate
    FROM customer_demographics
),
JoinedData AS (
    SELECT 
        a.ca_address_sk,
        a.full_address,
        a.city,
        a.state,
        a.zip,
        c.full_name,
        d.cd_gender,
        d.cd_marital_status,
        d.cd_education_status,
        d.cd_purchase_estimate
    FROM AddressSegments a
    JOIN CustomerNames c ON c.c_customer_sk = a.ca_address_sk
    JOIN Demographics d ON d.cd_demo_sk = c.c_current_cdemo_sk
)
SELECT 
    full_address,
    city,
    state,
    zip,
    full_name,
    cd_gender,
    cd_marital_status,
    cd_education_status,
    RANK() OVER (PARTITION BY cd_state ORDER BY cd_purchase_estimate DESC) AS purchase_rank
FROM JoinedData
WHERE 
    city LIKE '%ville%' AND
    cd_gender = 'F'
ORDER BY purchase_rank;
