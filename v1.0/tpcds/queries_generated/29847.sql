
WITH processed_customers AS (
    SELECT 
        c.c_customer_id,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        CASE 
            WHEN cd.cd_gender = 'M' THEN 'Male' 
            WHEN cd.cd_gender = 'F' THEN 'Female' 
            ELSE 'Other' 
        END AS gender,
        CONCAT(ca.ca_street_number, ' ', ca.ca_street_name, ', ', ca.ca_city, ', ', ca.ca_state, ' ', ca.ca_zip) AS full_address,
        SUBSTRING(c.email_address FROM 1 FOR POSITION('@' IN c.email_address) - 1) AS email_prefix
    FROM 
        customer AS c
    JOIN 
        customer_demographics AS cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address AS ca ON c.c_current_addr_sk = ca.ca_address_sk
),
sales_summary AS (
    SELECT 
        ws.ws_bill_customer_sk AS customer_id,
        SUM(ws.ws_net_paid) AS total_sales,
        COUNT(ws.ws_order_number) AS total_orders
    FROM 
        web_sales AS ws
    GROUP BY 
        ws.ws_bill_customer_sk
)
SELECT 
    pc.full_name,
    pc.gender,
    pc.full_address,
    ps.total_sales,
    ps.total_orders,
    COALESCE(ps.total_sales, 0) AS adjusted_sales
FROM 
    processed_customers AS pc
LEFT JOIN 
    sales_summary AS ps ON pc.c_customer_id = ps.customer_id
WHERE 
    pc.full_address ILIKE '%New York%'
ORDER BY 
    adjusted_sales DESC
LIMIT 10;
