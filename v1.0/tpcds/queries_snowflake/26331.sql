
WITH ranked_customers AS (
    SELECT 
        c.c_customer_id,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS rank
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
top_customers AS (
    SELECT 
        c_customer_id,
        full_name,
        cd_gender,
        cd_marital_status,
        cd_purchase_estimate
    FROM 
        ranked_customers
    WHERE 
        rank <= 10
),
customer_addresses AS (
    SELECT 
        ca.ca_address_id,
        ca.ca_street_name,
        ca.ca_city,
        ca.ca_state,
        ca.ca_zip
    FROM 
        customer_address ca
    JOIN 
        customer c ON ca.ca_address_sk = c.c_current_addr_sk
)
SELECT 
    tc.full_name,
    tc.cd_gender,
    tc.cd_marital_status,
    tc.cd_purchase_estimate,
    LISTAGG(CONCAT(ca.ca_street_name, ', ', ca.ca_city, ', ', ca.ca_state, ' ', ca.ca_zip), '; ') WITHIN GROUP (ORDER BY ca.ca_address_id) AS address_list
FROM 
    top_customers tc
LEFT JOIN 
    customer_addresses ca ON tc.c_customer_id = ca.ca_address_id
GROUP BY 
    tc.c_customer_id,
    tc.full_name, 
    tc.cd_gender, 
    tc.cd_marital_status, 
    tc.cd_purchase_estimate
ORDER BY 
    tc.cd_purchase_estimate DESC;
