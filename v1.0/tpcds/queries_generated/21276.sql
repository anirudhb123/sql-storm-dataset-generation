
WITH ranked_sales AS (
    SELECT 
        ws.web_site_sk,
        ws.web_name,
        ws.net_profit,
        RANK() OVER (PARTITION BY ws.web_site_sk ORDER BY ws.net_profit DESC) AS profit_rank
    FROM 
        web_sales ws
    INNER JOIN 
        customer c ON ws.ws_ship_customer_sk = c.c_customer_sk
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        cd.cd_gender = 'F' 
        AND cd.cd_marital_status IS NOT NULL 
        AND cd.cd_purchase_estimate > 1000
),
total_sales AS (
    SELECT 
        ws.web_site_sk,
        SUM(ws.net_profit) AS total_net_profit
    FROM 
        web_sales ws
    GROUP BY 
        ws.web_site_sk
),
inventory_info AS (
    SELECT 
        inv.inv_item_sk,
        SUM(inv.inv_quantity_on_hand) AS total_quantity
    FROM 
        inventory inv
    GROUP BY 
        inv.inv_item_sk
),
item_details AS (
    SELECT 
        i.i_item_sk,
        i.i_product_name,
        CASE 
            WHEN i.i_current_price > (SELECT AVG(i2.i_current_price) FROM item i2 WHERE i2.i_class_id = i.i_class_id)
            THEN 'Above Average'
            ELSE 'Below Average'
        END AS price_comparison
    FROM 
        item i
)
SELECT 
    ts.web_name,
    ts.total_net_profit,
    ir.total_quantity,
    id.i_product_name,
    id.price_comparison
FROM 
    total_sales ts
JOIN 
    ranked_sales rs ON ts.web_site_sk = rs.web_site_sk AND rs.profit_rank = 1
LEFT JOIN 
    inventory_info ir ON ir.inv_item_sk IN (SELECT ws.ws_item_sk FROM web_sales ws WHERE ws.ws_sold_date_sk IN (SELECT d.d_date_sk FROM date_dim d WHERE d.d_year = 2023))
JOIN 
    item_details id ON id.i_item_sk = ir.inv_item_sk
WHERE 
    ts.total_net_profit IS NOT NULL
ORDER BY 
    ts.total_net_profit DESC,
    ir.total_quantity ASC
LIMIT 10;
