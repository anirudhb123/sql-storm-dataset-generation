
WITH customer_info AS (
    SELECT 
        c.c_customer_id,
        CONCAT(c.c_salutation, ' ', c.c_first_name, ' ', c.c_last_name) AS full_name,
        ca.ca_city AS city,
        ca.ca_state AS state,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        ROW_NUMBER() OVER (PARTITION BY ca.ca_city ORDER BY cd.cd_purchase_estimate DESC) AS city_rank
    FROM 
        customer c 
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        ca.ca_state IN ('CA', 'NY')
),
top_customers AS (
    SELECT 
        c.c_customer_id,
        c.full_name,
        c.city,
        c.state,
        c.cd_gender,
        c.cd_marital_status,
        c.cd_purchase_estimate
    FROM 
        customer_info c
    WHERE 
        c.city_rank <= 10
),
customer_counts AS (
    SELECT 
        city,
        COUNT(*) AS total_customers,
        AVG(cd_purchase_estimate) AS avg_purchase_estimate
    FROM 
        top_customers
    GROUP BY 
        city
)
SELECT 
    tc.city,
    cc.total_customers, 
    cc.avg_purchase_estimate,
    STRING_AGG(tc.full_name, '; ') AS top_customers_list
FROM 
    customer_counts cc
JOIN 
    top_customers tc ON cc.city = tc.city
GROUP BY 
    tc.city, cc.total_customers, cc.avg_purchase_estimate
ORDER BY 
    cc.total_customers DESC;
