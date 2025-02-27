
WITH customer_info AS (
    SELECT 
        c.c_customer_id,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        ca.ca_city,
        ca.ca_state,
        ca.ca_country,
        ca.ca_zip,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
sales_summary AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_net_paid) AS total_sales,
        COUNT(ws_order_number) AS total_orders
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
),
extended_info AS (
    SELECT 
        ci.c_customer_id,
        ci.full_name,
        ci.cd_gender,
        ci.cd_marital_status,
        ci.ca_city,
        ci.ca_state,
        ci.ca_country,
        ci.ca_zip,
        ci.cd_purchase_estimate,
        ci.cd_credit_rating,
        COALESCE(ss.total_sales, 0) AS total_sales,
        COALESCE(ss.total_orders, 0) AS total_orders
    FROM 
        customer_info ci
    LEFT JOIN 
        sales_summary ss ON ci.c_customer_id = ss.ws_bill_customer_sk
)
SELECT 
    full_name,
    cd_gender,
    cd_marital_status,
    ca_city,
    ca_state,
    ca_country,
    ca_zip,
    total_sales,
    total_orders,
    CASE 
        WHEN total_sales > 1000 THEN 'High Value'
        WHEN total_sales BETWEEN 500 AND 1000 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS customer_value_segment
FROM 
    extended_info
WHERE 
    ca_state IN ('CA', 'NY', 'TX')
ORDER BY 
    total_sales DESC;
