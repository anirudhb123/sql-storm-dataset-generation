
WITH popular_items AS (
    SELECT 
        ws_item_sk,
        COUNT(ws_order_number) AS order_count,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_profit) AS total_profit
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk
),
customer_stats AS (
    SELECT 
        c_customer_sk,
        cd_gender,
        cd_marital_status,
        COUNT(DISTINCT ws_order_number) AS total_orders,
        AVG(ws_net_profit) AS avg_profit
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        c_customer_sk, cd_gender, cd_marital_status
),
inventory_stats AS (
    SELECT 
        inv_item_sk, 
        SUM(inv_quantity_on_hand) AS total_stock
    FROM 
        inventory
    GROUP BY 
        inv_item_sk
),
item_performance AS (
    SELECT 
        i.i_item_sk,
        i.i_item_desc,
        pi.order_count,
        pi.total_quantity,
        pi.total_profit,
        COALESCE(is.total_stock, 0) AS stock_availability
    FROM 
        item i
    LEFT JOIN 
        popular_items pi ON i.i_item_sk = pi.ws_item_sk
    LEFT JOIN 
        inventory_stats is ON i.i_item_sk = is.inv_item_sk
)
SELECT 
    ip.i_item_desc,
    ip.order_count,
    ip.total_quantity,
    ip.total_profit,
    ip.stock_availability,
    cs.cd_gender,
    cs.cd_marital_status, 
    cs.total_orders,
    cs.avg_profit
FROM 
    item_performance ip
JOIN 
    customer_stats cs ON ip.total_profit > cs.avg_profit
WHERE 
    ip.stock_availability > 0
ORDER BY 
    ip.total_profit DESC
LIMIT 100;
