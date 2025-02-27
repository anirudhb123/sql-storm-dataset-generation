
WITH CustomerDetails AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        ca.ca_city,
        ca.ca_state,
        cd.cd_gender,
        CASE 
            WHEN cd.cd_marital_status = 'M' THEN 'Married' 
            ELSE 'Single' 
        END AS marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate
    FROM 
        customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
AddressStatistics AS (
    SELECT 
        ca.ca_city,
        ca.ca_state,
        COUNT(*) AS customer_count,
        AVG(cd_purchase_estimate) AS avg_purchase_estimate
    FROM 
        customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    GROUP BY 
        ca.ca_city, ca.ca_state
),
CombinedStats AS (
    SELECT 
        cd.c_first_name,
        cd.c_last_name,
        cd.ca_city,
        cd.ca_state,
        cd.cd_gender,
        cd.marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        as.customer_count,
        as.avg_purchase_estimate
    FROM 
        CustomerDetails cd
    JOIN AddressStatistics as ON cd.ca_city = as.ca_city AND cd.ca_state = as.ca_state
)
SELECT 
    CONCAT(c_first_name, ' ', c_last_name) AS full_name,
    ca_city,
    ca_state,
    cd_gender,
    marital_status,
    cd_education_status,
    cd_purchase_estimate,
    customer_count,
    avg_purchase_estimate,
    ROUND(cd_purchase_estimate / NULLIF(avg_purchase_estimate, 0), 2) AS relative_purchase_estimate
FROM 
    CombinedStats
WHERE 
    cd_purchase_estimate > (SELECT AVG(cd_purchase_estimate) FROM customer_demographics)
ORDER BY 
    relative_purchase_estimate DESC;
