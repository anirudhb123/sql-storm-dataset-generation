
WITH customer_info AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_credit_rating,
        cd.cd_purchase_estimate,
        ca.ca_city,
        ca.ca_state,
        ca.ca_country,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    WHERE 
        cd.cd_gender = 'F' AND cd.cd_marital_status = 'M'
),
aggregated_info AS (
    SELECT 
        ci.full_name,
        COUNT(ss.ss_ticket_number) AS total_purchases,
        SUM(ss.ss_ext_sales_price) AS total_spent
    FROM 
        customer_info ci
    LEFT JOIN 
        store_sales ss ON ss.ss_customer_sk = ci.c_customer_id
    GROUP BY 
        ci.full_name
)
SELECT 
    ai.full_name,
    ai.total_purchases,
    ai.total_spent,
    CASE 
        WHEN ai.total_spent > 1000 THEN 'High Value Customer'
        WHEN ai.total_spent BETWEEN 500 AND 1000 THEN 'Medium Value Customer'
        ELSE 'Low Value Customer'
    END AS customer_value
FROM 
    aggregated_info ai
ORDER BY 
    ai.total_spent DESC;
