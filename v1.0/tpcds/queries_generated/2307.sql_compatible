
WITH customer_sales AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_ext_sales_price) AS total_web_sales,
        COUNT(ws.ws_order_number) AS total_orders,
        AVG(ws.ws_net_profit) AS avg_net_profit
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_id
), 
item_performance AS (
    SELECT 
        i.i_item_id,
        SUM(ws.ws_quantity) AS total_quantity_sold,
        SUM(ws.ws_net_profit) AS total_net_profit
    FROM 
        item i
    JOIN 
        web_sales ws ON i.i_item_sk = ws.ws_item_sk
    GROUP BY 
        i.i_item_id
),
top_items AS (
    SELECT 
        i.i_item_id,
        ip.total_quantity_sold,
        ip.total_net_profit,
        RANK() OVER (ORDER BY ip.total_net_profit DESC) AS rank
    FROM 
        item_performance ip
)

SELECT 
    cs.c_customer_id,
    cs.total_web_sales,
    cs.total_orders,
    cs.avg_net_profit,
    ti.i_item_id,
    ti.total_quantity_sold,
    ti.total_net_profit
FROM 
    customer_sales cs
LEFT JOIN 
    top_items ti ON cs.total_orders > 0
WHERE 
    cs.total_web_sales IS NOT NULL
    AND cs.total_orders > 1
    AND (ti.rank <= 10 OR ti.total_net_profit >= 1000)
ORDER BY 
    cs.avg_net_profit DESC, 
    ti.total_net_profit DESC;
