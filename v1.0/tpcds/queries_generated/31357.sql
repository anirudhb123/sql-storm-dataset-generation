
WITH RECURSIVE item_sales AS (
    SELECT 
        ws_item_sk, 
        SUM(ws_quantity) AS total_quantity, 
        SUM(ws_net_profit) AS total_net_profit, 
        COUNT(DISTINCT ws_order_number) AS total_orders,
        RANK() OVER (ORDER BY SUM(ws_net_profit) DESC) AS profit_rank
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk
), 
customer_returns AS (
    SELECT 
        sr_item_sk, 
        SUM(sr_return_quantity) AS total_returned_quantity, 
        SUM(sr_return_amt) AS total_returned_amt
    FROM 
        store_returns
    GROUP BY 
        sr_item_sk
),
top_items AS (
    SELECT 
        it.i_item_id, 
        it.i_product_name, 
        COALESCE(is.total_quantity, 0) AS sold_quantity,
        COALESCE(is.total_net_profit, 0) AS net_profit,
        COALESCE(cr.total_returned_quantity, 0) AS returned_quantity,
        COALESCE(cr.total_returned_amt, 0) AS returned_amt
    FROM 
        item it
    LEFT JOIN 
        item_sales is ON it.i_item_sk = is.ws_item_sk
    LEFT JOIN 
        customer_returns cr ON it.i_item_sk = cr.sr_item_sk
    WHERE 
        (COALESCE(is.total_quantity, 0) > 0 OR COALESCE(cr.total_returned_quantity, 0) > 0)
)
SELECT 
    ti.i_item_id,
    ti.i_product_name,
    ti.sold_quantity,
    ti.net_profit,
    ti.returned_quantity,
    ti.returned_amt,
    (ti.net_profit - ti.returned_amt) AS final_profit
FROM 
    top_items ti
WHERE 
    (ti.final_profit > 1000 OR ti.returned_quantity > 5)
ORDER BY 
    final_profit DESC
LIMIT 10
OFFSET 5;
