
WITH customer_summary AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_net_profit) AS total_profit,
        AVG(ws.ws_quantity) AS avg_quantity
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        cd.cd_gender = 'F' AND
        cd.cd_marital_status = 'M'
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status, cd.cd_education_status
),
item_summary AS (
    SELECT 
        i.i_item_sk,
        i.i_product_name,
        SUM(ws.ws_quantity) AS total_quantity_sold,
        SUM(ws.ws_net_profit) AS total_profit_generated
    FROM 
        item i
    JOIN 
        web_sales ws ON i.i_item_sk = ws.ws_item_sk
    GROUP BY 
        i.i_item_sk, i.i_product_name
),
inventory_status AS (
    SELECT 
        inv.inv_item_sk,
        SUM(inv.inv_quantity_on_hand) AS total_on_hand
    FROM 
        inventory inv
    GROUP BY 
        inv.inv_item_sk
)
SELECT 
    cs.c_customer_sk,
    cs.c_first_name,
    cs.c_last_name,
    cs.total_orders,
    cs.total_profit,
    cs.avg_quantity,
    is.item_name,
    is.total_quantity_sold,
    is.total_profit_generated,
    inv.total_on_hand
FROM 
    customer_summary cs
JOIN 
    item_summary is ON cs.total_orders > 0
JOIN 
    inventory_status inv ON is.i_item_sk = inv.inv_item_sk
WHERE 
    inv.total_on_hand < 50
ORDER BY 
    cs.total_profit DESC, is.total_profit_generated DESC
LIMIT 100;
