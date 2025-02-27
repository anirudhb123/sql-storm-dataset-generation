
WITH customer_details AS (
    SELECT 
        c.c_customer_id,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        ca.ca_city,
        ca.ca_state,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        REPLACE(REPLACE(CONCAT(c.c_first_name, ' ', c.c_last_name), ' ', ''), '.', '') AS normalized_name
    FROM 
        customer c
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
sales_summary AS (
    SELECT 
        ws.ws_bill_customer_sk,
        SUM(ws.ws_net_sales) AS total_net_sales,
        COUNT(ws.ws_order_number) AS total_orders
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_bill_customer_sk
),
order_analysis AS (
    SELECT 
        cd.full_name,
        cd.ca_city,
        cd.ca_state,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        ss.total_net_sales,
        ss.total_orders,
        CASE 
            WHEN ss.total_net_sales > 1000 THEN 'High Value'
            WHEN ss.total_net_sales BETWEEN 500 AND 1000 THEN 'Medium Value'
            ELSE 'Low Value'
        END AS customer_value
    FROM 
        customer_details cd
    LEFT JOIN 
        sales_summary ss ON cd.c_customer_id = ss.ws_bill_customer_sk
)
SELECT 
    full_name,
    ca_city,
    ca_state,
    cd_gender,
    cd_marital_status,
    cd_education_status,
    total_net_sales,
    total_orders,
    customer_value
FROM 
    order_analysis
WHERE 
    normalized_name LIKE '%john%' 
    AND ca_state IN ('CA', 'TX', 'NY')
ORDER BY 
    total_net_sales DESC, full_name;
