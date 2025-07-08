
WITH AddressCounts AS (
    SELECT 
        ca_state, 
        COUNT(*) AS address_count,
        LISTAGG(ca_city, '; ') WITHIN GROUP (ORDER BY ca_city) AS cities,
        LISTAGG(DISTINCT CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type), '; ') WITHIN GROUP (ORDER BY CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type)) AS street_details
    FROM 
        customer_address
    GROUP BY 
        ca_state
),
CustomerDemographics AS (
    SELECT 
        cd_gender,
        COUNT(DISTINCT c_customer_sk) AS customer_count,
        SUM(cd_dep_count) AS total_dependents,
        AVG(cd_purchase_estimate) AS avg_purchase_estimate
    FROM 
        customer 
    JOIN 
        customer_demographics ON c_current_cdemo_sk = cd_demo_sk
    GROUP BY 
        cd_gender
)
SELECT 
    a.ca_state,
    a.address_count,
    a.cities,
    a.street_details,
    c.cd_gender,
    c.customer_count,
    c.total_dependents,
    c.avg_purchase_estimate
FROM 
    AddressCounts a
JOIN 
    CustomerDemographics c ON a.address_count > 100
ORDER BY 
    a.ca_state, c.cd_gender;
