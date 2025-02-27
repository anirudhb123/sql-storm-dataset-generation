
WITH CustomerAggregates AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating,
        ROW_NUMBER() OVER(PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS rank
    FROM 
        customer AS c
    JOIN 
        customer_demographics AS cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
TopCustomers AS (
    SELECT 
        ca.ca_city,
        COUNT(*) AS customer_count,
        STRING_AGG(DISTINCT ca.ca_state) AS states_covered,
        SUM(ca.cd_purchase_estimate) AS total_estimate
    FROM 
        CustomerAggregates AS ca
    WHERE 
        ca.rank <= 10
    GROUP BY 
        ca.ca_city
)
SELECT 
    city,
    customer_count,
    states_covered,
    total_estimate,
    TRIM(LOWER(SUBSTRING(states_covered FROM 1 FOR 2))) AS initial_states_code
FROM 
    TopCustomers
WHERE 
    customer_count > 1
ORDER BY 
    total_estimate DESC
LIMIT 5;
