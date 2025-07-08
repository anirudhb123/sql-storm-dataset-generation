
WITH ranked_customers AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS rank_by_purchase
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        c.c_birth_year BETWEEN 1980 AND 1990
),
address_summary AS (
    SELECT 
        ca.ca_address_sk,
        ca.ca_city AS city,
        ca.ca_state AS state,
        COUNT(DISTINCT c.c_customer_sk) AS customer_count,
        LISTAGG(CONCAT(c.c_first_name, ' ', c.c_last_name), ', ') WITHIN GROUP (ORDER BY c.c_first_name) AS customer_names
    FROM 
        customer_address ca
    JOIN 
        customer c ON ca.ca_address_sk = c.c_current_addr_sk
    GROUP BY 
        ca.ca_address_sk, ca.ca_city, ca.ca_state
),
final_summary AS (
    SELECT 
        rc.full_name,
        rc.cd_gender,
        rc.cd_marital_status,
        rc.cd_purchase_estimate,
        asu.city,
        asu.state,
        asu.customer_count,
        asu.customer_names
    FROM 
        ranked_customers rc
    JOIN 
        address_summary asu ON rc.c_customer_sk IN (SELECT c.c_customer_sk FROM customer c WHERE c.c_current_addr_sk = asu.ca_address_sk)
    WHERE 
        rc.rank_by_purchase <= 10
)
SELECT 
    fs.full_name,
    fs.cd_gender,
    fs.cd_marital_status,
    fs.cd_purchase_estimate,
    fs.city,
    fs.state,
    fs.customer_count,
    fs.customer_names
FROM 
    final_summary fs
ORDER BY 
    fs.cd_purchase_estimate DESC;
