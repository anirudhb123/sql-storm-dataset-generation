
WITH top_customers AS (
    SELECT 
        c.c_customer_id,
        SUM(ss.ss_net_profit) AS total_profit
    FROM 
        customer c
    JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    WHERE 
        ss.ss_sold_date_sk BETWEEN 2452031 AND 2452395
    GROUP BY 
        c.c_customer_id
    ORDER BY 
        total_profit DESC
    LIMIT 10
),
recent_returns AS (
    SELECT 
        sr.sr_item_sk,
        SUM(sr.sr_return_quantity) AS total_returns
    FROM 
        store_returns sr
    WHERE 
        sr.sr_returned_date_sk BETWEEN 2452031 AND 2452395
    GROUP BY 
        sr.sr_item_sk
),
inventory_levels AS (
    SELECT 
        inv.inv_item_sk,
        SUM(inv.inv_quantity_on_hand) AS total_quantity
    FROM 
        inventory inv
    GROUP BY 
        inv.inv_item_sk
),
sales_data AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_net_sales) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk BETWEEN 2452031 AND 2452395
    GROUP BY 
        ws.ws_item_sk
)
SELECT 
    c.c_customer_id,
    COALESCE(sd.total_sales, 0) AS total_sales,
    COALESCE(rr.total_returns, 0) AS total_returns,
    COALESCE(il.total_quantity, 0) AS inventory_level,
    ct.total_profit
FROM 
    top_customers ct
LEFT JOIN 
    sales_data sd ON ct.c_customer_id = sd.ws_item_sk
LEFT JOIN 
    recent_returns rr ON sd.ws_item_sk = rr.sr_item_sk
LEFT JOIN 
    inventory_levels il ON sd.ws_item_sk = il.inv_item_sk
ORDER BY 
    ct.total_profit DESC, total_sales DESC;
