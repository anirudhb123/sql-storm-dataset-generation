
WITH ProcessedAddresses AS (
    SELECT 
        LOWER(CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type)) AS full_address,
        ca_city,
        ca_state
    FROM 
        customer_address
),
ProcessedCustomers AS (
    SELECT 
        CONCAT(c.first_name, ' ', c.last_name) AS full_name,
        cd.gender,
        cd.marital_status,
        cd.education_status,
        cd.purchase_estimate,
        cd.credit_rating,
        ca.full_address,
        ca.ca_city,
        ca.ca_state
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        ProcessedAddresses ca ON c.c_current_addr_sk = ca.ca_address_sk
),
AggregatedData AS (
    SELECT 
        pc.full_name,
        COUNT(pc.purchase_estimate) AS purchase_count,
        SUM(pc.purchase_estimate) AS total_estimate,
        STRING_AGG(DISTINCT pc.ca_state, ', ') AS states
    FROM 
        ProcessedCustomers pc
    GROUP BY 
        pc.full_name
)
SELECT 
    ad.full_name,
    ad.purchase_count,
    ad.total_estimate,
    ad.states,
    CASE 
        WHEN COUNT(ad.total_estimate) > 100 THEN 'High Potential'
        WHEN COUNT(ad.total_estimate) BETWEEN 50 AND 100 THEN 'Medium Potential'
        ELSE 'Low Potential'
    END AS potential_category
FROM 
    AggregatedData ad
WHERE 
    ad.total_estimate > 5000
ORDER BY 
    ad.total_estimate DESC
LIMIT 50;
