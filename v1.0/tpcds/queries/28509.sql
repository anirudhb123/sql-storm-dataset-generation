
WITH AddressInfo AS (
    SELECT 
        ca_address_sk,
        ca_city,
        ca_state,
        CONCAT(ca_city, ', ', ca_state) AS full_address,
        LENGTH(ca_street_name) AS street_length,
        UPPER(ca_street_type) AS upper_street_type
    FROM 
        customer_address
),
CustomerInfo AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        ai.full_address,
        ai.street_length,
        ai.upper_street_type
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        AddressInfo ai ON c.c_current_addr_sk = ai.ca_address_sk
),
AggregatedData AS (
    SELECT 
        ci.cd_gender,
        ci.cd_marital_status,
        COUNT(*) AS customer_count,
        AVG(ci.street_length) AS avg_street_length,
        STRING_AGG(DISTINCT ci.upper_street_type, ', ') AS street_types
    FROM 
        CustomerInfo ci
    GROUP BY 
        ci.cd_gender, ci.cd_marital_status
)
SELECT 
    ad.cd_gender,
    ad.cd_marital_status,
    ad.customer_count,
    ad.avg_street_length,
    ad.street_types
FROM 
    AggregatedData ad
ORDER BY 
    ad.cd_gender, ad.cd_marital_status;
