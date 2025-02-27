
WITH processed_data AS (
    SELECT 
        c.c_first_name || ' ' || c.c_last_name AS full_name,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type, 
               CASE WHEN ca_suite_number IS NOT NULL THEN CONCAT(' Suite ', ca_suite_number) ELSE '' END) AS full_address,
        cd.cd_gender,
        cd.cd_income_band_sk,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_net_paid) AS total_spent
    FROM 
        customer c
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        cd.cd_gender = 'F'
        AND ca.ca_state = 'CA'
    GROUP BY 
        c.c_first_name, c.c_last_name, ca.ca_street_number, 
        ca.ca_street_name, ca.ca_street_type, 
        ca.ca_suite_number, cd.cd_gender, cd.cd_income_band_sk
)
SELECT 
    full_name,
    full_address,
    cd_gender,
    cd_income_band_sk,
    total_orders,
    total_spent
FROM 
    processed_data
WHERE 
    total_orders > 10
ORDER BY 
    total_spent DESC
LIMIT 50;
