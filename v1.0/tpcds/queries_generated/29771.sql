
WITH customer_info AS (
    SELECT 
        c.c_customer_id, 
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name, 
        cd.cd_gender, 
        CA.ca_city,
        CA.ca_state,
        CASE 
            WHEN cd.cd_marital_status = 'M' THEN 'Married'
            ELSE 'Single'
        END AS marital_status
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address CA ON c.c_current_addr_sk = CA.ca_address_sk
),
sales_info AS (
    SELECT 
        ws_bill_customer_sk, 
        SUM(ws_net_paid) AS total_sales,
        COUNT(ws_order_number) AS order_count
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
)
SELECT 
    ci.c_customer_id,
    ci.full_name,
    ci.cd_gender,
    ci.ca_city,
    ci.ca_state,
    ci.marital_status,
    COALESCE(si.total_sales, 0) AS total_sales,
    COALESCE(si.order_count, 0) AS order_count
FROM 
    customer_info ci
LEFT JOIN 
    sales_info si ON ci.c_customer_id = si.ws_bill_customer_sk
WHERE 
    ci.ca_state = 'NY' AND 
    (ci.cd_gender = 'M' OR ci.marital_status = 'Married')
ORDER BY 
    total_sales DESC;
