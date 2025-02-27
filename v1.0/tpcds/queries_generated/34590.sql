
WITH RECURSIVE inventory_trend AS (
    SELECT 
        inv_date_sk, 
        inv_item_sk, 
        inv_quantity_on_hand,
        1 as trend_level
    FROM 
        inventory
    WHERE 
        inv_quantity_on_hand < 50
    UNION ALL
    SELECT 
        inv.inv_date_sk,
        inv.inv_item_sk,
        inv.inv_quantity_on_hand,
        it.trend_level + 1
    FROM 
        inventory inv
    JOIN 
        inventory_trend it ON inv.inv_item_sk = it.inv_item_sk
    WHERE 
        inv.inv_date_sk > it.inv_date_sk AND 
        inv.inv_quantity_on_hand < 50
),
customer_info AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        d.cd_gender,
        d.cd_marital_status,
        d.cd_purchase_estimate,
        ROW_NUMBER() OVER (PARTITION BY d.cd_gender ORDER BY d.cd_purchase_estimate DESC) as rank
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics d ON c.c_current_cdemo_sk = d.cd_demo_sk
)
SELECT 
    ci.c_customer_sk,
    ci.c_first_name,
    ci.c_last_name,
    ci.cd_gender,
    ci.cd_marital_status,
    SUM(ws.ws_ext_sales_price) as total_sales,
    AVG(ws.ws_net_profit) as avg_net_profit,
    COUNT(DISTINCT inv.trend_level) as trend_levels_count
FROM 
    customer_info ci
LEFT JOIN 
    web_sales ws ON ci.c_customer_sk = ws.ws_bill_customer_sk
LEFT JOIN 
    inventory_trend inv ON ws.ws_item_sk = inv.inv_item_sk
WHERE 
    ci.rank <= 5
    AND ci.cd_purchase_estimate IS NOT NULL
GROUP BY 
    ci.c_customer_sk, ci.c_first_name, ci.c_last_name, ci.cd_gender, ci.cd_marital_status
HAVING 
    SUM(ws.ws_ext_sales_price) > 1000
ORDER BY 
    total_sales DESC;
