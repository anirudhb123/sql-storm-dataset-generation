WITH CustomerAnalytics AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating,
        ca.ca_city,
        ROW_NUMBER() OVER(PARTITION BY ca.ca_city ORDER BY cd.cd_purchase_estimate DESC) AS city_rank
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    WHERE 
        cd.cd_purchase_estimate IS NOT NULL
),
TopCustomers AS (
    SELECT 
        c.* 
    FROM 
        CustomerAnalytics c
    WHERE 
        c.city_rank <= 10
)
SELECT 
    ca.ca_city,
    COUNT(tc.c_customer_id) AS top_customers_count,
    AVG(tc.cd_purchase_estimate) AS avg_purchase_estimate,
    STRING_AGG(CONCAT(tc.c_first_name, ' ', tc.c_last_name), '; ') AS customer_names
FROM 
    CustomerAnalytics ca
LEFT JOIN 
    TopCustomers tc ON ca.c_customer_id = tc.c_customer_id
GROUP BY 
    ca.ca_city
HAVING 
    COUNT(tc.c_customer_id) > 0
ORDER BY 
    avg_purchase_estimate DESC 
LIMIT 5;