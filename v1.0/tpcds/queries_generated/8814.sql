
WITH CustomerInfo AS (
    SELECT 
        c.c_customer_id, 
        c.c_first_name, 
        c.c_last_name, 
        cd.cd_gender, 
        cd.cd_marital_status, 
        cd.cd_education_status,
        SUM(ws.ws_net_profit) AS total_net_profit
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        c.c_birth_year BETWEEN 1980 AND 1995
    GROUP BY 
        c.c_customer_id, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status, cd.cd_education_status
),
SalesInfo AS (
    SELECT 
        i.i_item_id,
        i.i_product_name,
        SUM(ws.ws_quantity) AS total_quantity_sold,
        SUM(ws.ws_net_profit) AS total_net_profit_item
    FROM 
        item i
    JOIN 
        web_sales ws ON i.i_item_sk = ws.ws_item_sk
    GROUP BY 
        i.i_item_id, i.i_product_name
),
WarehouseInfo AS (
    SELECT 
        w.w_warehouse_id,
        SUM(inv.inv_quantity_on_hand) AS total_quantity_on_hand
    FROM 
        warehouse w
    JOIN 
        inventory inv ON w.w_warehouse_sk = inv.inv_warehouse_sk
    GROUP BY 
        w.w_warehouse_id
)

SELECT 
    ci.c_customer_id,
    ci.c_first_name,
    ci.c_last_name,
    ci.cd_gender,
    ci.cd_marital_status,
    si.i_item_id,
    si.i_product_name,
    si.total_quantity_sold,
    si.total_net_profit_item,
    wi.w_warehouse_id,
    wi.total_quantity_on_hand
FROM 
    CustomerInfo ci
JOIN 
    SalesInfo si ON ci.total_net_profit > 1000
JOIN 
    WarehouseInfo wi ON si.total_quantity_sold > 10
ORDER BY 
    ci.c_last_name, si.total_net_profit_item DESC;
