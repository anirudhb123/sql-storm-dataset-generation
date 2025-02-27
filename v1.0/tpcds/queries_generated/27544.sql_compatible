
WITH ranked_customers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        ca.ca_city,
        ca.ca_state,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        RANK() OVER (PARTITION BY ca.ca_state ORDER BY cd.cd_purchase_estimate DESC) AS purchase_rank
    FROM 
        customer c
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
top_customers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        ca.ca_city,
        ca.ca_state,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate
    FROM 
        ranked_customers c
    JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    WHERE 
        c.purchase_rank <= 5
)
SELECT 
    tc.ca_city,
    tc.ca_state,
    COUNT(tc.c_customer_sk) AS total_top_customers,
    AVG(tc.cd_purchase_estimate) AS avg_purchase_estimate,
    MIN(tc.cd_purchase_estimate) AS min_purchase_estimate,
    MAX(tc.cd_purchase_estimate) AS max_purchase_estimate,
    STRING_AGG(DISTINCT tc.cd_gender, ', ') AS genders,
    STRING_AGG(DISTINCT tc.cd_marital_status, ', ') AS marital_statuses
FROM 
    top_customers tc
GROUP BY 
    tc.ca_city, tc.ca_state
ORDER BY 
    total_top_customers DESC;
