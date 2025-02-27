
WITH AddressComponents AS (
    SELECT 
        ca_address_id, 
        ca_street_number || ' ' || ca_street_name || ' ' || ca_street_type AS full_address,
        ca_city,
        ca_state,
        ca_zip,
        LENGTH(ca_street_name) AS street_name_length
    FROM 
        customer_address
),
CustomerDetails AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name || ' ' || c.c_last_name AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        ac.full_address,
        ac.city,
        ac.state,
        ac.zip
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        AddressComponents ac ON c.c_current_addr_sk = ac.ca_address_id
),
AggregatedData AS (
    SELECT 
        cd.gender,
        COUNT(*) AS total_customers,
        AVG(cd.cd_purchase_estimate) AS avg_purchase_estimate,
        MAX(cd.cd_purchase_estimate) AS max_purchase_estimate,
        MIN(cd.cd_purchase_estimate) AS min_purchase_estimate
    FROM 
        CustomerDetails cd
    GROUP BY 
        cd.gender
)
SELECT 
    ad.gender,
    ad.total_customers,
    ad.avg_purchase_estimate,
    ad.max_purchase_estimate,
    ad.min_purchase_estimate
FROM 
    AggregatedData ad
ORDER BY 
    ad.total_customers DESC;
