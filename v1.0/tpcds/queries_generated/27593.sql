
WITH CustomerData AS (
    SELECT 
        c.c_customer_id,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        CASE 
            WHEN cd_gender = 'M' THEN 'Male' 
            WHEN cd_gender = 'F' THEN 'Female' 
            ELSE 'Other' 
        END AS gender,
        cd_marital_status AS marital_status,
        cd_education_status AS education,
        ca_city AS city,
        ca_state AS state,
        ca_country AS country,
        cd_purchase_estimate,
        cd_credit_rating,
        REPLACE(REPLACE(REPLACE(cd_buy_potential, 'High', 'Excellent'), 'Medium', 'Good'), 'Low', 'Fair') AS potential_category
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
RankedCustomers AS (
    SELECT 
        *,
        RANK() OVER (PARTITION BY potential_category ORDER BY cd_purchase_estimate DESC) AS rank
    FROM CustomerData
)
SELECT 
    full_name,
    gender,
    marital_status,
    education,
    city,
    state,
    country,
    cd_purchase_estimate,
    potential_category
FROM RankedCustomers
WHERE rank <= 10
ORDER BY potential_category, cd_purchase_estimate DESC;
