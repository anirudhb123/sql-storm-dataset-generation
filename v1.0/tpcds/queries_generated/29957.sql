
WITH customer_data AS (
    SELECT 
        c.c_customer_id,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        CASE 
            WHEN cd_gender = 'M' THEN 'Male'
            WHEN cd_gender = 'F' THEN 'Female'
            ELSE 'Other'
        END AS gender,
        cd_marital_status,
        cd_education_status,
        ca_city,
        ca_state,
        ca_country
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
purchase_statistics AS (
    SELECT 
        customer_id,
        COUNT(DISTINCT ws_order_number) AS total_orders,
        SUM(ws_sales_price) AS total_spent,
        AVG(ws_sales_price) AS avg_order_value
    FROM 
        web_sales
    GROUP BY 
        customer_id
),
demographic_analysis AS (
    SELECT 
        cd.gender,
        cd.marital_status,
        cd.education_status,
        p.total_orders,
        p.total_spent,
        p.avg_order_value,
        ROW_NUMBER() OVER (PARTITION BY cd.gender ORDER BY p.total_spent DESC) AS rank_by_spent
    FROM 
        customer_data cd
    JOIN 
        purchase_statistics p ON cd.c_customer_id = p.customer_id
)
SELECT 
    gender,
    marital_status,
    education_status,
    COUNT(*) AS customer_count,
    AVG(total_spent) AS avg_spent,
    AVG(avg_order_value) AS avg_order_value,
    MAX(total_orders) AS max_orders
FROM 
    demographic_analysis
WHERE 
    rank_by_spent <= 10
GROUP BY 
    gender, marital_status, education_status
ORDER BY 
    gender, marital_status;
