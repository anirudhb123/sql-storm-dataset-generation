
WITH sales_summary AS (
    SELECT 
        ws.web_site_sk,
        COUNT(ws.ws_order_number) AS total_orders,
        SUM(ws.ws_net_profit) AS total_profit,
        AVG(ws.ws_sales_price) AS avg_sales_price,
        SUM(ws.ws_ext_discount_amt) AS total_discount
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_ship_customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        cd.cd_marital_status = 'M' 
        AND cd.cd_gender = 'F' 
        AND cd.cd_purchase_estimate > 1000
    GROUP BY 
        ws.web_site_sk
),
inventory_data AS (
    SELECT 
        inv.inv_item_sk, 
        SUM(inv.inv_quantity_on_hand) AS total_inventory
    FROM 
        inventory inv
    JOIN
        item i ON inv.inv_item_sk = i.i_item_sk
    WHERE 
        i.i_current_price > 20
    GROUP BY 
        inv.inv_item_sk
),
high_profit_sales AS (
    SELECT 
        s.ss_item_sk,
        SUM(s.ss_net_profit) AS total_net_profit
    FROM 
        store_sales s
    WHERE 
        s.ss_sales_price > (
            SELECT 
                AVG(ss_sales_price) 
            FROM 
                store_sales
        )
    GROUP BY 
        s.ss_item_sk
)
SELECT 
    sw.w_warehouse_id,
    hs.total_orders,
    hs.total_profit,
    hw.total_inventory,
    hps.total_net_profit
FROM 
    warehouse sw
LEFT JOIN 
    sales_summary hs ON sw.w_warehouse_sk = hs.web_site_sk
LEFT JOIN 
    inventory_data hw ON hw.inv_item_sk IN (SELECT i.i_item_sk FROM item i WHERE i.i_current_price > 20)
LEFT JOIN 
    high_profit_sales hps ON hps.s_sales_price = sw.w_warehouse_sk
WHERE 
    hs.total_profit IS NOT NULL
    AND hw.total_inventory IS NOT NULL
ORDER BY 
    hs.total_profit DESC
LIMIT 10;
