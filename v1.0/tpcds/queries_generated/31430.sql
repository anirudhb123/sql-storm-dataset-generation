
WITH RECURSIVE sales_data AS (
    SELECT 
        ws_order_number, 
        ws_item_sk, 
        ws_quantity, 
        ws_net_profit 
    FROM 
        web_sales 
    WHERE 
        ws_sold_date_sk >= 20230501 
    UNION ALL 
    SELECT 
        cs_order_number, 
        cs_item_sk, 
        cs_quantity, 
        cs_net_profit 
    FROM 
        catalog_sales 
    WHERE 
        cs_sold_date_sk >= 20230501 
),
customer_info AS (
    SELECT 
        c.c_customer_id, 
        c.c_first_name, 
        c.c_last_name, 
        cd.cd_gender, 
        COUNT(DISTINCT ws_order_number) AS total_orders, 
        SUM(ws_net_profit) AS total_profit 
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk 
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk 
    GROUP BY 
        c.c_customer_id, 
        c.c_first_name, 
        c.c_last_name, 
        cd.cd_gender
),
inventory_data AS (
    SELECT 
        i.i_item_sk, 
        SUM(inv_quantity_on_hand) AS total_inventory 
    FROM 
        item i 
    JOIN 
        inventory inv ON i.i_item_sk = inv.inv_item_sk 
    GROUP BY 
        i.i_item_sk
)
SELECT 
    ci.c_customer_id, 
    ci.c_first_name, 
    ci.c_last_name, 
    SUM(sd.ws_quantity) AS total_quantity, 
    SUM(COALESCE(sd.ws_net_profit, 0) + COALESCE(sd.cs_net_profit, 0)) AS overall_net_profit, 
    COALESCE(id.total_inventory, 0) AS inventory_on_hand 
FROM 
    customer_info ci 
LEFT JOIN 
    sales_data sd ON ci.c_customer_id = sd.ws_order_number 
LEFT JOIN 
    inventory_data id ON sd.ws_item_sk = id.i_item_sk 
GROUP BY 
    ci.c_customer_id, 
    ci.c_first_name, 
    ci.c_last_name, 
    id.total_inventory 
HAVING 
    overall_net_profit > 10000 
ORDER BY 
    inventory_on_hand DESC, 
    overall_net_profit DESC
LIMIT 100;
