
WITH customer_info AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cad.ca_city,
        cad.ca_state,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address cad ON c.c_current_addr_sk = cad.ca_address_sk
),
inventory_summary AS (
    SELECT 
        i.i_item_id,
        SUM(inv.inv_quantity_on_hand) AS total_quantity
    FROM 
        inventory inv
    JOIN 
        item i ON inv.inv_item_sk = i.i_item_sk
    GROUP BY 
        i.i_item_id
),
sales_data AS (
    SELECT 
        ws.ws_bill_customer_sk,
        SUM(ws.ws_net_profit) AS total_profit
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_bill_customer_sk
),
customer_benchmark AS (
    SELECT 
        ci.full_name,
        ci.ca_city,
        ci.ca_state,
        ci.cd_gender,
        ci.cd_marital_status,
        ci.cd_education_status,
        ci.cd_purchase_estimate,
        is.total_quantity,
        sd.total_profit
    FROM 
        customer_info ci
    LEFT JOIN 
        inventory_summary is ON ci.c_customer_sk = is.i_item_id
    LEFT JOIN 
        sales_data sd ON ci.c_customer_sk = sd.ws_bill_customer_sk
)
SELECT 
    cb.full_name,
    cb.ca_city,
    cb.ca_state,
    cb.cd_gender,
    cb.cd_marital_status,
    cb.cd_education_status,
    cb.cd_purchase_estimate,
    COALESCE(cb.total_quantity, 0) AS total_quantity_on_hand,
    COALESCE(cb.total_profit, 0) AS total_profit
FROM 
    customer_benchmark cb
WHERE 
    cb.cd_gender = 'F'
    AND cb.cd_purchase_estimate > 50000
ORDER BY 
    cb.total_profit DESC
LIMIT 100;
