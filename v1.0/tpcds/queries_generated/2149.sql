
WITH sales_data AS (
    SELECT 
        ws.ws_sold_date_sk,
        ws.ws_item_sk,
        ws.ws_quantity,
        ws.ws_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sold_date_sk DESC) as rn
    FROM 
        web_sales ws
    JOIN 
        item i ON ws.ws_item_sk = i.i_item_sk
    WHERE 
        i.i_current_price > 50 AND 
        ws.ws_sold_date_sk BETWEEN 2400 AND 2500
),
customer_returns AS (
    SELECT 
        wr_returning_customer_sk,
        SUM(wr_return_amt) AS total_returned_amt,
        COUNT(wr_order_number) AS return_count
    FROM 
        web_returns
    GROUP BY 
        wr_returning_customer_sk
),
best_customers AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_net_profit) AS total_profit
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_id
    HAVING 
        SUM(ws.ws_net_profit) > 1000
),
inventory_summary AS (
    SELECT 
        inv.inv_item_sk,
        SUM(inv.inv_quantity_on_hand) AS total_quantity
    FROM 
        inventory inv
    GROUP BY 
        inv.inv_item_sk
)
SELECT 
    c.c_customer_id,
    SUM(sd.ws_net_profit) AS total_web_sales_profit,
    COALESCE(cr.total_returned_amt, 0) AS total_returned_amt,
    COALESCE(cr.return_count, 0) AS return_count,
    ISNULL(i.total_quantity, 0) AS total_inventory,
    COUNT(DISTINCT sd.ws_item_sk) AS unique_items_sold
FROM 
    best_customers bc
LEFT JOIN 
    sales_data sd ON bc.c_customer_id = sd.ws_item_sk
LEFT JOIN 
    customer_returns cr ON cr.wr_returning_customer_sk = bc.c_customer_id
LEFT JOIN 
    inventory_summary i ON i.inv_item_sk = sd.ws_item_sk
WHERE 
    sd.rn = 1
GROUP BY 
    c.c_customer_id, cr.total_returned_amt, cr.return_count, i.total_quantity
ORDER BY 
    total_web_sales_profit DESC;
