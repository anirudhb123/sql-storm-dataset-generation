
WITH customer_details AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        LENGTH(CONCAT(c.c_first_name, ' ', c.c_last_name)) AS full_name_length
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
address_details AS (
    SELECT 
        ca.ca_address_id,
        ca.ca_street_name,
        ca.ca_city,
        ca.ca_state,
        CONCAT(ca.ca_street_name, ', ', ca.ca_city, ', ', ca.ca_state) AS full_address,
        LENGTH(CONCAT(ca.ca_street_name, ', ', ca.ca_city, ', ', ca.ca_state)) AS address_length
    FROM 
        customer_address ca
),
sales_summary AS (
    SELECT 
        ws.ws_order_number,
        SUM(ws.ws_sales_price) AS total_sales,
        COUNT(ws.ws_item_sk) AS item_count
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_order_number
)
SELECT 
    cd.full_name,
    cd.cd_gender,
    cd.cd_marital_status,
    ad.full_address,
    ad.address_length,
    ss.total_sales,
    ss.item_count,
    CASE 
        WHEN ss.total_sales >= 1000 THEN 'High Value'
        WHEN ss.total_sales >= 500 THEN 'Medium Value'
        ELSE 'Low Value' 
    END AS customer_value_category
FROM 
    customer_details cd
JOIN 
    address_details ad ON cd.c_customer_id = ad.ca_address_id 
LEFT JOIN 
    sales_summary ss ON cd.c_customer_id = ss.ws_order_number
ORDER BY 
    cd.full_name ASC, ss.total_sales DESC
LIMIT 100;
