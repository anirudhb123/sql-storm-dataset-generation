
WITH RECURSIVE sales_data AS (
    SELECT 
        ws.ws_order_number, 
        ws.ws_item_sk, 
        ws.ws_quantity, 
        ws.ws_sales_price, 
        ws.ws_net_profit,
        1 AS recursion_level
    FROM web_sales ws
    WHERE ws.ws_sold_date_sk = (SELECT MAX(ws1.ws_sold_date_sk) FROM web_sales ws1)

    UNION ALL

    SELECT 
        ws.ws_order_number, 
        ws.ws_item_sk, 
        ws.ws_quantity, 
        ws.ws_sales_price, 
        (sd.ws_net_profit + ws.ws_net_profit) AS ws_net_profit,
        sd.recursion_level + 1
    FROM web_sales ws
    JOIN sales_data sd ON ws.ws_order_number = sd.ws_order_number
    WHERE sd.recursion_level < 3
)

, customer_return AS (
    SELECT
        sr.sr_item_sk,
        COALESCE(SUM(sr.sr_return_quantity), 0) AS total_return_quantity,
        COALESCE(SUM(sr.sr_return_amt_inc_tax), 0) AS total_return_amt
    FROM store_returns sr
    GROUP BY sr.sr_item_sk
)

SELECT 
    i.i_item_id,
    i.i_item_desc,
    COALESCE(sd.ws_quantity, 0) AS total_sold_quantity,
    COALESCE(cr.total_return_quantity, 0) AS total_return_quantity,
    (COALESCE(sd.ws_net_profit, 0) - COALESCE(cr.total_return_amt, 0)) AS net_profit_after_returns,
    COUNT(DISTINCT c.c_customer_sk) AS unique_customers 
FROM item i
LEFT JOIN sales_data sd ON i.i_item_sk = sd.ws_item_sk
LEFT JOIN customer_return cr ON i.i_item_sk = cr.sr_item_sk
LEFT JOIN web_sales ws ON i.i_item_sk = ws.ws_item_sk
LEFT JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
WHERE 
    (i.i_current_price > 10 AND cr.total_return_quantity > 0)
    OR (i.i_current_price < 5 AND sd.ws_quantity > 100)
GROUP BY i.i_item_id, i.i_item_desc
ORDER BY net_profit_after_returns DESC
FETCH FIRST 50 ROWS ONLY;
