
WITH AddressDetails AS (
    SELECT 
        ca.city AS city,
        ca.state AS state,
        COUNT(DISTINCT c.c_customer_sk) AS customer_count,
        AVG(cd_purchase_estimate) AS avg_purchase_estimate
    FROM
        customer_address ca
    JOIN 
        customer c ON c.c_current_addr_sk = ca.ca_address_sk
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        ca.city, ca.state
),
AggregatedDetails AS (
    SELECT 
        CONCAT(city, ', ', state) AS full_address,
        customer_count,
        avg_purchase_estimate,
        RANK() OVER (ORDER BY avg_purchase_estimate DESC) AS rank
    FROM 
        AddressDetails
)
SELECT 
    full_address, 
    customer_count,
    avg_purchase_estimate
FROM 
    AggregatedDetails
WHERE 
    rank <= 10
ORDER BY 
    avg_purchase_estimate DESC;
