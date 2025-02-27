
WITH filtered_customers AS (
    SELECT 
        CONCAT(c_first_name, ' ', c_last_name) AS full_name,
        ca_city,
        cd_gender,
        cd_marital_status,
        cd_purchase_estimate
    FROM 
        customer 
    JOIN 
        customer_demographics ON c_current_cdemo_sk = cd_demo_sk
    JOIN 
        customer_address ON c_current_addr_sk = ca_address_sk
    WHERE 
        cd_purchase_estimate > 5000
),

ranked_customers AS (
    SELECT 
        full_name,
        ca_city,
        cd_gender,
        cd_marital_status,
        cd_purchase_estimate,
        ROW_NUMBER() OVER (PARTITION BY ca_city ORDER BY cd_purchase_estimate DESC) AS city_rank
    FROM 
        filtered_customers
)

SELECT 
    CONCAT('Rank ', city_rank, ': ', full_name, ' from ', ca_city, ' is a ', cd_gender, 
           ' with marital status ', cd_marital_status, ' and purchase estimate of $', 
           FORMAT(cd_purchase_estimate, 2)) AS customer_summary
FROM 
    ranked_customers
WHERE 
    city_rank <= 5
ORDER BY 
    ca_city, city_rank;
