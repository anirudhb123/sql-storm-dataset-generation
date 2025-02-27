
WITH ranked_customers AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS purchase_rank
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
address_summary AS (
    SELECT 
        ca.ca_address_sk,
        ca.ca_city,
        ca.ca_state,
        COUNT(distinct c.c_customer_sk) AS customer_count,
        STRING_AGG(DISTINCT CONCAT(c.c_first_name, ' ', c.c_last_name), ', ') AS customer_names
    FROM 
        customer_address ca
    JOIN 
        customer c ON ca.ca_address_sk = c.c_current_addr_sk 
    GROUP BY 
        ca.ca_address_sk, ca.ca_city, ca.ca_state
),
top_customers AS (
    SELECT 
        rc.full_name,
        rc.cd_gender,
        rc.cd_marital_status,
        rc.cd_education_status,
        asum.ca_city,
        asum.ca_state,
        asum.customer_count
    FROM 
        ranked_customers rc
    JOIN 
        address_summary asum ON rc.c_customer_sk IN (SELECT c.c_customer_sk FROM customer c JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk WHERE ca.ca_city = asum.ca_city AND ca.ca_state = asum.ca_state)
    WHERE 
        rc.purchase_rank <= 10
)
SELECT 
    full_name,
    cd_gender,
    cd_marital_status,
    cd_education_status,
    ca_city,
    ca_state,
    customer_count
FROM 
    top_customers
ORDER BY 
    ca_state, ca_city, full_name;
