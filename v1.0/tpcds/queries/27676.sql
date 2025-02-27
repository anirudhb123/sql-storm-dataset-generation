
WITH RankedCustomers AS (
    SELECT 
        c.c_customer_id,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS rank
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
FilteredCustomers AS (
    SELECT 
        rc.c_customer_id,
        rc.full_name,
        rc.cd_gender,
        rc.cd_marital_status,
        rc.cd_education_status,
        rc.cd_purchase_estimate
    FROM 
        RankedCustomers rc
    WHERE 
        rc.rank <= 10
)
SELECT 
    fc.cd_gender,
    COUNT(fc.c_customer_id) AS customer_count,
    AVG(fc.cd_purchase_estimate) AS average_purchase_estimate,
    STRING_AGG(fc.full_name, ', ') AS top_customers
FROM 
    FilteredCustomers fc
GROUP BY 
    fc.cd_gender
ORDER BY 
    customer_count DESC;
