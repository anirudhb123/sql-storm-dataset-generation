
WITH AddressCounts AS (
    SELECT 
        ca_city,
        COUNT(*) AS address_count
    FROM 
        customer_address
    GROUP BY 
        ca_city
),
TopCities AS (
    SELECT 
        ca_city
    FROM 
        AddressCounts
    WHERE 
        address_count > (SELECT AVG(address_count) FROM AddressCounts)
),
CustomerDetails AS (
    SELECT 
        c.c_customer_id, 
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name, 
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        c.c_city IN (SELECT ca_city FROM TopCities)
)
SELECT 
    cd.full_name,
    cd.cd_gender,
    CASE 
        WHEN cd.cd_marital_status = 'M' THEN 'Married'
        WHEN cd.cd_marital_status = 'S' THEN 'Single'
        ELSE 'Other'
    END AS marital_status,
    cd.cd_education_status,
    cd.cd_purchase_estimate
FROM 
    CustomerDetails cd
ORDER BY 
    cd.cd_purchase_estimate DESC;
