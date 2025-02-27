
WITH RankedCustomers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        ca.ca_city,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY c.c_birth_year DESC) AS gender_rank
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
CityGrouped AS (
    SELECT 
        ca.city,
        STRING_AGG(CONCAT(c.c_first_name, ' ', c.c_last_name) ORDER BY c.c_last_name) AS customers_list,
        COUNT(*) AS customer_count
    FROM 
        customer_address ca
    JOIN 
        customer c ON c.c_current_addr_sk = ca.ca_address_sk
    WHERE 
        ca.ca_city IS NOT NULL
    GROUP BY 
        ca.city
),
TopCities AS (
    SELECT 
        city, 
        customer_count,
        ROW_NUMBER() OVER (ORDER BY customer_count DESC) AS city_rank
    FROM 
        CityGrouped
)
SELECT 
    rc.c_first_name,
    rc.c_last_name,
    rc.cd_gender,
    rc.cd_marital_status,
    rc.cd_education_status,
    gc.city,
    gc.customers_list,
    gc.customer_count
FROM 
    RankedCustomers rc
JOIN 
    TopCities gc ON rc.gender_rank = 1  -- filter to get top male customer for each gender
WHERE 
    rc.c_customer_sk IN 
    (SELECT 
        MIN(c_customer_sk)
     FROM 
        RankedCustomers 
     GROUP BY 
        cd_gender
    )
ORDER BY 
    gc.customer_count DESC;
