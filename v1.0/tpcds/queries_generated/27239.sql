
WITH AddressDetails AS (
    SELECT 
        ca_city, 
        ca_state, 
        ca_country, 
        COUNT(*) AS address_count
    FROM 
        customer_address
    GROUP BY 
        ca_city, 
        ca_state, 
        ca_country
), 
DemographicDetails AS (
    SELECT 
        cd_gender, 
        cd_marital_status, 
        SUM(cd_purchase_estimate) AS total_purchase_estimate
    FROM 
        customer_demographics
    GROUP BY 
        cd_gender, 
        cd_marital_status
),
CustomerInfo AS (
    SELECT 
        c.c_customer_id, 
        c.c_first_name, 
        c.c_last_name, 
        ca.ca_city, 
        ca.ca_state, 
        ca.ca_country, 
        cd.cd_gender, 
        cd.cd_marital_status
    FROM 
        customer c
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
), 
StringAnalysis AS (
    SELECT 
        customer_id, 
        first_name,
        last_name, 
        LENGTH(first_name) AS first_name_length, 
        LENGTH(last_name) AS last_name_length, 
        CONCAT(first_name, ' ', last_name) AS full_name,
        LOWER(full_name) AS full_name_lower,
        UPPER(full_name) AS full_name_upper
    FROM 
        CustomerInfo
)
SELECT 
    sa.full_name, 
    sa.first_name_length, 
    sa.last_name_length, 
    ad.address_count, 
    dd.total_purchase_estimate
FROM 
    StringAnalysis sa
JOIN 
    AddressDetails ad ON sa.address_count = ad.address_count
JOIN 
    DemographicDetails dd ON sa.gender = dd.cd_gender AND sa.marital_status = dd.cd_marital_status
WHERE 
    ad.address_count > 5 
ORDER BY 
    sa.first_name_length DESC;
