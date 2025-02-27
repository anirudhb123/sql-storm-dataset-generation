
WITH AddressDetails AS (
    SELECT 
        ca.city, 
        ca.state, 
        STRING_AGG(DISTINCT CONCAT(c.c_first_name, ' ', c.c_last_name), '; ') AS customer_names,
        COUNT(DISTINCT c.c_customer_sk) AS customer_count
    FROM 
        customer_address ca
    JOIN 
        customer c ON c.c_current_addr_sk = ca.ca_address_sk
    WHERE 
        ca.state IN ('CA', 'NY', 'TX') 
    GROUP BY 
        ca.city, ca.state
),
CustomerDemographics AS (
    SELECT 
        cd.cd_gender, 
        cd.cd_marital_status,
        SUM(cd.cd_dep_count) AS total_dependents,
        AVG(cd.cd_purchase_estimate) AS avg_purchase_estimate
    FROM 
        customer_demographics cd
    GROUP BY 
        cd.cd_gender, cd.cd_marital_status
)
SELECT 
    ad.city, 
    ad.state, 
    ad.customer_names, 
    ad.customer_count,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.total_dependents,
    cd.avg_purchase_estimate
FROM 
    AddressDetails ad
JOIN 
    CustomerDemographics cd ON (ad.customer_count > 10 AND cd.cd_marital_status = 'M')
ORDER BY 
    ad.state, ad.city;
