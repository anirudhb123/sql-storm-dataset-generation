
WITH address_details AS (
    SELECT 
        ca_address_sk,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type, ', ', ca_city, ', ', ca_state, ' ', ca_zip) AS full_address,
        LENGTH(CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type, ', ', ca_city, ', ', ca_state, ' ', ca_zip)) AS address_length
    FROM 
        customer_address
),
customer_info AS (
    SELECT 
        c_customer_sk,
        CONCAT(c_first_name, ' ', c_last_name) AS full_name,
        cd_gender,
        cd_marital_status,
        cd_income_band_sk,
        cd_purchase_estimate,
        cd_credit_rating
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
formatted_data AS (
    SELECT
        ci.c_customer_sk,
        ci.full_name,
        ci.cd_gender,
        ci.cd_marital_status,
        ab.full_address,
        ab.address_length,
        ci.cd_purchase_estimate,
        ci.cd_credit_rating,
        RANK() OVER (PARTITION BY ci.cd_gender ORDER BY ci.cd_purchase_estimate DESC) AS purchase_rank
    FROM 
        customer_info ci
    JOIN 
        address_details ab ON ci.c_customer_sk = ab.ca_address_sk
)
SELECT 
    full_name,
    cd_gender,
    cd_marital_status,
    full_address,
    address_length,
    cd_purchase_estimate,
    cd_credit_rating,
    purchase_rank
FROM 
    formatted_data
WHERE 
    purchase_rank <= 10
ORDER BY 
    cd_gender, purchase_rank;
