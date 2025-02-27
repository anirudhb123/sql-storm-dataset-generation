
WITH ranked_customers AS (
    SELECT 
        c.c_customer_id,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS rank
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
customer_addresses AS (
    SELECT 
        ca.ca_address_id,
        ca.ca_city,
        ca.ca_state,
        ca.ca_country
    FROM 
        customer_address ca
    JOIN 
        customer c ON c.c_current_addr_sk = ca.ca_address_sk
),
sales_summary AS (
    SELECT
        ws.ws_bill_customer_sk,
        SUM(ws.ws_net_profit) AS total_profit,
        COUNT(ws.ws_order_number) AS total_orders
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_bill_customer_sk
)
SELECT 
    rc.full_name,
    rc.cd_gender,
    rc.cd_marital_status,
    ca.ca_city,
    ca.ca_state,
    ca.ca_country,
    ss.total_profit,
    ss.total_orders
FROM 
    ranked_customers rc
JOIN 
    customer_addresses ca ON rc.c_customer_id = ca.ca_address_id
JOIN 
    sales_summary ss ON rc.c_customer_id = ss.ws_bill_customer_sk
WHERE 
    rc.rank <= 5 
ORDER BY 
    rc.cd_gender, ss.total_profit DESC;
