
WITH customer_info AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
), 
address_info AS (
    SELECT 
        ca.ca_address_id,
        ca.ca_city,
        ca.ca_state,
        CONCAT(ca.ca_street_number, ' ', ca.ca_street_name, ' ', ca.ca_street_type) AS full_address
    FROM 
        customer_address ca
), 
sales_info AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_quantity,
        ws.ws_sales_price,
        ws.ws_net_paid,
        ws.ws_net_profit,
        d.d_date
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
)
SELECT 
    ci.full_name,
    ci.cd_gender,
    ci.cd_marital_status,
    ci.cd_purchase_estimate,
    ai.full_address,
    si.ws_order_number,
    si.ws_quantity,
    si.ws_sales_price,
    si.ws_net_paid,
    si.ws_net_profit,
    CASE 
        WHEN si.ws_net_profit > 100 THEN 'High Profit' 
        WHEN si.ws_net_profit BETWEEN 50 AND 100 THEN 'Medium Profit' 
        ELSE 'Low Profit' 
    END AS profit_category,
    ROW_NUMBER() OVER (PARTITION BY ci.cd_gender, ai.ca_state ORDER BY si.ws_net_profit DESC) AS rank
FROM 
    customer_info ci
JOIN 
    address_info ai ON ai.ca_address_id = (SELECT ca.ca_address_id FROM customer_address ca WHERE ca.ca_address_sk = c.c_current_addr_sk)
JOIN 
    sales_info si ON si.ws_bill_customer_sk = ci.c_customer_id
WHERE 
    ci.cd_purchase_estimate > 500
ORDER BY 
    profit_category DESC, si.ws_net_profit DESC;
