
WITH customer_info AS (
    SELECT 
        c.c_customer_id,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        ca.ca_city,
        ca.ca_state,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        c.c_email_address
    FROM 
        customer c
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
sales_info AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_ext_sales_price) AS total_sales
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
),
combined_info AS (
    SELECT 
        ci.*,
        COALESCE(si.total_sales, 0) AS total_sales
    FROM 
        customer_info ci
    LEFT JOIN 
        sales_info si ON ci.c_customer_id = si.ws_bill_customer_sk
)
SELECT 
    full_name,
    ca_city,
    ca_state,
    cd_gender,
    cd_marital_status,
    cd_education_status,
    total_sales,
    CASE 
        WHEN total_sales <= 100 THEN 'Low Spender'
        WHEN total_sales BETWEEN 101 AND 500 THEN 'Medium Spender'
        ELSE 'High Spender'
    END AS spending_category
FROM 
    combined_info
WHERE 
    ca_state = 'CA'
ORDER BY 
    total_sales DESC
LIMIT 50;
