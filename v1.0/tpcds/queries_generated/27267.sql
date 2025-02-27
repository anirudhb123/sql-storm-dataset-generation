
WITH AddressCity AS (
    SELECT 
        ca_city,
        COUNT(DISTINCT ca_address_sk) AS city_count,
        STRING_AGG(ca_street_name || ' ' || ca_street_type, ', ') AS street_names
    FROM 
        customer_address
    GROUP BY 
        ca_city
), 
DemographicStats AS (
    SELECT 
        cd_gender,
        COUNT(c_customer_sk) AS customer_count,
        AVG(cd_purchase_estimate) AS avg_purchase_estimate
    FROM 
        customer 
    JOIN 
        customer_demographics ON c_current_cdemo_sk = cd_demo_sk
    GROUP BY 
        cd_gender
),
CombinedStats AS (
    SELECT 
        ac.ca_city,
        ac.city_count,
        ac.street_names,
        ds.cd_gender,
        ds.customer_count,
        ds.avg_purchase_estimate
    FROM 
        AddressCity ac
    JOIN 
        DemographicStats ds ON (ac.city_count > 10 AND ds.customer_count > 50)
)
SELECT 
    ca_city,
    city_count,
    street_names,
    cd_gender,
    customer_count,
    avg_purchase_estimate,
    CONCAT('City: ', ca_city, ', ");
    CASE 
        WHEN avg_purchase_estimate > 1000 THEN 'High Spender'
        WHEN avg_purchase_estimate BETWEEN 500 AND 1000 THEN 'Moderate Spender'
        ELSE 'Low Spender'
    END AS spending_category,
    CURRENT_DATE AS query_date
FROM 
    CombinedStats
ORDER BY 
    city_count DESC, customer_count DESC;
