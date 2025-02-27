
WITH AddressSummary AS (
    SELECT 
        ca.city,
        ca.state,
        COUNT(DISTINCT c.c_customer_sk) AS customer_count,
        AVG(cd.cd_purchase_estimate) AS avg_purchase_estimate,
        STRING_AGG(DISTINCT cd.cd_gender) AS gender_distribution
    FROM 
        customer_address ca
    JOIN 
        customer c ON ca.ca_address_sk = c.c_current_addr_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        ca.city, ca.state
), ProcessedData AS (
    SELECT 
        city,
        state,
        customer_count,
        avg_purchase_estimate,
        gender_distribution,
        REPLACE(gender_distribution, ',', ' & ') AS formatted_gender_distribution,
        CONCAT(customer_count, ' customers in ', city, ', ', state, ': Gender distribution is ', formatted_gender_distribution) AS final_summary
    FROM 
        AddressSummary
)
SELECT 
    final_summary
FROM 
    ProcessedData
WHERE 
    customer_count > 10
ORDER BY 
    avg_purchase_estimate DESC
LIMIT 5;
