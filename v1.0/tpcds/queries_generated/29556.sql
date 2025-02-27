
WITH AddressData AS (
    SELECT 
        ca_address_sk,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        ca_city,
        ca_state,
        ca_zip,
        LENGTH(ca_street_name) AS street_name_length,
        UPPER(ca_city) AS city_upper,
        LOWER(ca_state) AS state_lower
    FROM 
        customer_address
),
CustomerData AS (
    SELECT 
        c_customer_sk,
        CONCAT(c_first_name, ' ', c_last_name) AS full_name,
        cd_income_band_sk,
        cd_gender,
        LENGTH(c_login) AS login_length,
        cd_purchase_estimate
    FROM 
        customer
    JOIN 
        customer_demographics ON cd_demo_sk = c_current_cdemo_sk
),
CombinedData AS (
    SELECT 
        ad.full_address, 
        ad.ca_city,
        ad.ca_state,
        cd.full_name,
        cd.cd_gender,
        cd.cd_purchase_estimate,
        ad.street_name_length,
        cd.login_length
    FROM 
        AddressData ad
    JOIN 
        CustomerData cd ON cd.c_customer_sk % 10 = ad.ca_address_sk % 10
)
SELECT 
    ca_city,
    ca_state,
    AVG(street_name_length) AS avg_street_name_length,
    COUNT(DISTINCT full_name) AS unique_customers,
    SUM(cd_purchase_estimate) AS total_purchase_estimate
FROM 
    CombinedData
GROUP BY 
    ca_city, ca_state
ORDER BY 
    total_purchase_estimate DESC, avg_street_name_length ASC;
