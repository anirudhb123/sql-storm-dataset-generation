
WITH AddressCounts AS (
    SELECT 
        ca_city, 
        ca_state, 
        COUNT(*) AS address_count,
        STRING_AGG(ca_street_number || ' ' || ca_street_name || ' ' || ca_street_type, ', ') AS full_streets
    FROM 
        customer_address
    GROUP BY 
        ca_city, 
        ca_state
),
CustomerFullName AS (
    SELECT 
        c_customer_sk,
        (c_first_name || ' ' || c_last_name) AS full_name,
        c_birth_country
    FROM 
        customer
    WHERE 
        c_birth_country IS NOT NULL
),
CombinedInfo AS (
    SELECT 
        cf.full_name,
        ac.ca_city,
        ac.ca_state,
        ac.address_count,
        ac.full_streets,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status
    FROM 
        CustomerFullName cf
    JOIN 
        customer_demographics cd ON cf.c_customer_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON ca.ca_address_sk = cf.c_current_addr_sk
    JOIN 
        AddressCounts ac ON ac.ca_city = ca.ca_city AND ac.ca_state = ca.ca_state
)
SELECT 
    ci.full_name,
    ci.ca_city,
    ci.ca_state,
    ci.address_count,
    ci.full_streets,
    ci.cd_gender,
    ci.cd_marital_status,
    ci.cd_education_status
FROM 
    CombinedInfo ci
WHERE 
    ci.cd_gender = 'F'
    AND ci.cd_marital_status = 'M'
ORDER BY 
    ci.ca_state, 
    ci.address_count DESC;
