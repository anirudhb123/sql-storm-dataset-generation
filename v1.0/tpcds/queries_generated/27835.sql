
WITH customer_info AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        CONCAT(ca.ca_street_number, ' ', ca.ca_street_name, ' ', ca.ca_street_type, ', ', ca.ca_city, ', ', ca.ca_state, ' ', ca.ca_zip) AS full_address,
        cs.ss_quantity,
        SUM(cs.ss_net_paid) AS total_spent
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN 
        store_sales cs ON c.c_customer_sk = cs.ss_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status, cd.cd_education_status, ca.ca_street_number, ca.ca_street_name, ca.ca_street_type, ca.ca_city, ca.ca_state, ca.ca_zip
),
ranked_customers AS (
    SELECT 
        *,
        RANK() OVER (ORDER BY total_spent DESC) AS rank
    FROM 
        customer_info
)
SELECT 
    rank,
    full_name,
    cd_gender,
    cd_marital_status,
    cd_education_status,
    full_address,
    total_spent
FROM 
    ranked_customers
WHERE 
    rank <= 10
ORDER BY 
    rank;
