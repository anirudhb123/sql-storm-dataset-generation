
WITH AddressData AS (
    SELECT 
        ca.city AS city, 
        ca.state AS state, 
        COUNT(c.c_customer_sk) AS customer_count,
        AVG(cd.cd_purchase_estimate) AS avg_purchase_estimate
    FROM 
        customer_address ca
    JOIN 
        customer c ON ca.ca_address_sk = c.c_current_addr_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        ca.city, ca.state
),
RankedAddress AS (
    SELECT 
        city, 
        state, 
        customer_count, 
        avg_purchase_estimate,
        RANK() OVER (ORDER BY customer_count DESC, avg_purchase_estimate DESC) AS rank
    FROM 
        AddressData
)
SELECT 
    ra.city,
    ra.state,
    ra.customer_count,
    ra.avg_purchase_estimate,
    CONCAT('City: ', ra.city, ', State: ', ra.state, ' has ', ra.customer_count, ' customers with an average purchase estimate of ', ra.avg_purchase_estimate) AS description
FROM 
    RankedAddress ra
WHERE 
    ra.rank <= 10
ORDER BY 
    ra.rank;
