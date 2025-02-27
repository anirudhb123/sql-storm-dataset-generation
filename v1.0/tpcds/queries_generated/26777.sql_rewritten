WITH AddressDetails AS (
    SELECT 
        ca_address_sk,
        ca_street_number,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        UPPER(ca_city) AS upper_city,
        LOWER(ca_country) AS lower_country,
        ca_zip
    FROM 
        customer_address
),
CustomerDetails AS (
    SELECT 
        c_customer_sk,
        c_first_name,
        c_last_name,
        CONCAT(c_first_name, ' ', c_last_name) AS full_name,
        cd_gender,
        cd_marital_status,
        cd_purchase_estimate,
        cd_credit_rating
    FROM 
        customer
    JOIN 
        customer_demographics ON c_current_cdemo_sk = cd_demo_sk
),
CombinedDetails AS (
    SELECT 
        a.full_address,
        a.upper_city,
        a.lower_country,
        c.full_name,
        c.cd_gender,
        c.cd_marital_status,
        c.cd_purchase_estimate,
        c.cd_credit_rating
    FROM 
        AddressDetails a
    JOIN 
        CustomerDetails c ON a.ca_address_sk = c.c_customer_sk % 1000 
)
SELECT 
    upper_city,
    COUNT(*) AS number_of_customers,
    STRING_AGG(CONCAT(full_name, ' (', cd_gender, ', ', cd_marital_status, ')'), ', ') AS customer_names
FROM 
    CombinedDetails
GROUP BY 
    upper_city
ORDER BY 
    number_of_customers DESC
LIMIT 10;