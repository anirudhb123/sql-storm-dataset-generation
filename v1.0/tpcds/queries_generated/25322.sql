
WITH AddressComparison AS (
    SELECT 
        ca.city,
        COUNT(DISTINCT customer.c_customer_id) AS customer_count,
        AVG(candidate.length) AS avg_address_length,
        STRING_AGG(ca.ca_street_name || ' ' || ca.ca_street_number || ' ' || ca.ca_street_type, ', ') AS all_addresses
    FROM 
        customer_address ca
    JOIN 
        customer ON ca.ca_address_sk = customer.c_current_addr_sk
    LEFT JOIN 
        (
            SELECT 
                LENGTH(ca_street_name || ' ' || ca_street_number || ' ' || ca_street_type) AS length,
                ca_city
            FROM 
                customer_address
        ) AS candidate ON candidate.ca_city = ca.ca_city
    GROUP BY 
        ca.city
),
DemographicsAggregation AS (
    SELECT 
        cd.cd_gender,
        cd.cd_marital_status,
        COUNT(DISTINCT customer.c_customer_id) AS demographic_count,
        SUM(cd.cd_purchase_estimate) AS total_purchase_estimate
    FROM 
        customer_demographics cd
    JOIN 
        customer ON cd.cd_demo_sk = customer.c_current_cdemo_sk
    GROUP BY 
        cd.cd_gender, 
        cd.cd_marital_status
),
FinalBenchmark AS (
    SELECT 
        ac.city,
        ac.customer_count,
        ac.avg_address_length,
        da.cd_gender,
        da.cd_marital_status,
        da.demographic_count,
        da.total_purchase_estimate
    FROM 
        AddressComparison ac
    JOIN 
        DemographicsAggregation da ON ac.customer_count = da.demographic_count
)
SELECT 
    city,
    customer_count,
    avg_address_length,
    cd_gender,
    cd_marital_status,
    demographic_count,
    total_purchase_estimate
FROM 
    FinalBenchmark
ORDER BY 
    customer_count DESC, 
    avg_address_length DESC;
