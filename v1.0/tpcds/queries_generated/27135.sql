
WITH AddressData AS (
    SELECT 
        ca_address_id, 
        ca_street_name, 
        ca_city, 
        ca_state, 
        ca_zip,
        LENGTH(ca_street_name) AS street_name_length,
        LOWER(ca_city) AS city_lower,
        UPPER(ca_state) AS state_upper,
        CONCAT(ca_street_number, ' ', ca_street_name) AS full_address
    FROM 
        customer_address
), DemographicData AS (
    SELECT 
        cd_demo_sk,
        cd_gender,
        cd_marital_status,
        cd_education_status,
        CASE 
            WHEN cd_purchase_estimate < 50000 THEN 'Low'
            WHEN cd_purchase_estimate BETWEEN 50000 AND 100000 THEN 'Medium'
            ELSE 'High'
        END AS purchase_estimate_category
    FROM 
        customer_demographics
), CustomerData AS (
    SELECT 
        c.c_customer_id, 
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name, 
        d.purchase_estimate_category,
        a.ca_city, 
        a.full_address 
    FROM 
        customer c
    JOIN 
        DemographicData d ON c.c_current_cdemo_sk = d.cd_demo_sk
    JOIN 
        AddressData a ON c.c_current_addr_sk = a.ca_address_id
)
SELECT 
    cd.full_name, 
    cd.purchase_estimate_category, 
    cd.ca_city, 
    cd.full_address,
    COUNT(DISTINCT ca.ca_address_id) AS address_count,
    AVG(cd.street_name_length) AS avg_street_name_length
FROM 
    CustomerData cd
JOIN 
    AddressData ca ON cd.full_address = ca.full_address
GROUP BY 
    cd.full_name, 
    cd.purchase_estimate_category, 
    cd.ca_city, 
    cd.full_address
HAVING 
    COUNT(DISTINCT ca.ca_address_id) > 0
ORDER BY 
    cd.purchase_estimate_category DESC, 
    cd.full_name ASC;
