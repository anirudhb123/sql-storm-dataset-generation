
WITH RankedCustomers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY c.c_birth_year DESC) AS rn
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
FilteredCustomers AS (
    SELECT 
        fc.c_customer_sk,
        fc.c_first_name,
        fc.c_last_name,
        fc.cd_gender,
        fc.cd_marital_status,
        fc.cd_education_status
    FROM 
        RankedCustomers fc
    WHERE 
        fc.rn <= 5
),
AggregatedInfo AS (
    SELECT 
        fc.cd_gender,
        COUNT(*) AS customer_count,
        LISTAGG(CONCAT(fc.c_first_name, ' ', fc.c_last_name), ', ') AS top_customers
    FROM 
        FilteredCustomers fc
    GROUP BY 
        fc.cd_gender
)
SELECT 
    ai.cd_gender,
    ai.customer_count,
    ai.top_customers,
    SUM(CASE WHEN cd.cd_marital_status = 'M' THEN 1 ELSE 0 END) AS married_count,
    SUM(CASE WHEN cd.cd_marital_status = 'S' THEN 1 ELSE 0 END) AS single_count
FROM 
    AggregatedInfo ai
JOIN 
    customer_demographics cd ON cd.cd_demo_sk IN (SELECT c.c_current_cdemo_sk FROM customer c WHERE CONCAT(c.c_first_name, ' ', c.c_last_name) IN (SELECT VALUE FROM TABLE(FLATTEN(INPUT => SPLIT(ai.top_customers, ', ')))))
GROUP BY 
    ai.cd_gender, ai.customer_count, ai.top_customers
ORDER BY 
    ai.cd_gender;
