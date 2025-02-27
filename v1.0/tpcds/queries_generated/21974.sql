
WITH RankedReturns AS (
    SELECT 
        sr_item_sk,
        SUM(sr_return_quantity) AS total_returned,
        RANK() OVER (PARTITION BY sr_item_sk ORDER BY SUM(sr_return_quantity) DESC) AS rank
    FROM 
        store_returns
    GROUP BY 
        sr_item_sk
),
CustomerInfo AS (
    SELECT 
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        ca.ca_state,
        ROW_NUMBER() OVER (PARTITION BY ca.ca_state ORDER BY cd.cd_purchase_estimate DESC) AS rn
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    WHERE 
        cd.cd_purchase_estimate IS NOT NULL
),
HighValueReturns AS (
    SELECT 
        ci.c_customer_id,
        ci.cd_gender,
        ci.cd_marital_status,
        ci.cd_purchase_estimate,
        COALESCE(rr.total_returned, 0) AS total_returned
    FROM 
        CustomerInfo ci
    LEFT JOIN 
        RankedReturns rr ON ci.c_customer_id = rr.sr_item_sk
)
SELECT 
    c.c_customer_id,
    SUM(CASE 
        WHEN r.total_returned > 10 THEN r.total_returned ELSE NULL END
    ) AS high_value_returns,
    MAX(ci.cd_gender) AS gender,
    COUNT(DISTINCT ci.cd_marital_status) AS marital_status_count,
    STRING_AGG(DISTINCT ci.ca_state, ', ') AS states
FROM 
    HighValueReturns r
JOIN 
    customer c ON c.c_customer_id = r.c_customer_id
JOIN 
    CustomerInfo ci ON ci.c_customer_id = r.c_customer_id
WHERE 
    high_value_returns IS NOT NULL
GROUP BY 
    c.c_customer_id
HAVING 
    COUNT(DISTINCT ci.ca_state) > 1
ORDER BY 
    high_value_returns DESC
LIMIT 50;
