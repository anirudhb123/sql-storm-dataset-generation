
WITH Ranked_Customers AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS purchase_rank
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
Filtered_Customers AS (
    SELECT 
        rc.c_customer_sk,
        rc.full_name,
        rc.cd_gender,
        rc.cd_marital_status,
        rc.cd_education_status,
        rc.cd_purchase_estimate,
        rc.cd_credit_rating
    FROM 
        Ranked_Customers rc
    WHERE 
        rc.purchase_rank <= 10
),
Address_Stats AS (
    SELECT 
        ca_address_sk,
        COUNT(DISTINCT ca_city) AS city_count,
        COUNT(DISTINCT ca_state) AS state_count,
        COUNT(DISTINCT ca_country) AS country_count
    FROM 
        customer_address
    GROUP BY 
        ca_address_sk
)
SELECT 
    fc.full_name,
    fc.cd_gender,
    fc.cd_marital_status,
    fc.cd_education_status,
    fc.cd_purchase_estimate,
    fc.cd_credit_rating,
    as.city_count,
    as.state_count,
    as.country_count
FROM 
    Filtered_Customers fc
JOIN 
    customer c ON fc.c_customer_sk = c.c_customer_sk
JOIN 
    Address_Stats as ON c.c_current_addr_sk = as.ca_address_sk
ORDER BY 
    fc.cd_purchase_estimate DESC;
