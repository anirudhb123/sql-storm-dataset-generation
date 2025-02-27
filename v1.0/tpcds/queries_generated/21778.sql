
WITH customer_return_summary AS (
    SELECT 
        c.c_customer_sk,
        c.c_customer_id,
        COALESCE(SUM(sr_return_quantity), 0) AS total_returned_quantity,
        COALESCE(SUM(sr_return_amt), 0) AS total_returned_amount,
        COUNT(DISTINCT sr_ticket_number) AS number_of_returns
    FROM customer c
    LEFT JOIN store_returns sr ON c.c_customer_sk = sr.sr_customer_sk
    GROUP BY c.c_customer_sk, c.c_customer_id
), 
item_sales_summary AS (
    SELECT 
        ws.ws_item_sk,
        COUNT(ws.ws_order_number) AS total_orders,
        SUM(ws.ws_sales_price) AS total_sales,
        SUM(ws.ws_quantity) AS total_quantity_sold
    FROM web_sales ws
    GROUP BY ws.ws_item_sk
), 
high_return_items AS (
    SELECT 
        sr_item_sk,
        SUM(total_returned_quantity) AS returned_quantity_total,
        SUM(total_returned_amount) AS returned_amount_total
    FROM (
        SELECT 
            sr.sr_item_sk,
            SUM(sr.sr_return_quantity) AS total_returned_quantity,
            SUM(sr.sr_return_amt) AS total_returned_amount
        FROM store_returns sr
        JOIN customer_return_summary crs ON sr.sr_customer_sk = crs.c_customer_sk
        GROUP BY sr.sr_item_sk
    ) AS subquery
    GROUP BY sr_item_sk
), 
item_with_high_returns AS (
    SELECT
        i.i_item_sk,
        i.i_item_id,
        ISNULL(hi.returned_quantity_total, 0) AS total_returns,
        i.i_current_price,
        (SELECT AVG(ws.ws_net_profit) 
         FROM web_sales ws 
         WHERE ws.ws_item_sk = i.i_item_sk) AS average_net_profit
    FROM item i
    LEFT JOIN high_return_items hi ON i.i_item_sk = hi.sr_item_sk
    WHERE i.i_current_price > (
        SELECT AVG(i_current_price) FROM item
    )
    AND (hi.returned_quantity_total > (SELECT AVG(returned_quantity_total) FROM high_return_items))
), 
final_selection AS (
    SELECT 
        iwh.i_item_sk,
        iwh.i_item_id,
        iwh.total_returns,
        iwh.i_current_price,
        iwh.average_net_profit,
        CASE 
            WHEN iwh.average_net_profit IS NULL THEN 'NO DATA' 
            WHEN iwh.average_net_profit < 0 THEN 'LOSS'
            ELSE 'PROFIT'
        END AS profit_status
    FROM item_with_high_returns iwh
)
SELECT 
    f.i_item_sk,
    f.i_item_id,
    f.total_returns,
    f.i_current_price,
    f.average_net_profit,
    f.profit_status,
    ROW_NUMBER() OVER (PARTITION BY f.profit_status ORDER BY f.total_returns DESC) AS return_rank
FROM final_selection f
WHERE f.total_returns > (
    SELECT AVG(total_returns) FROM final_selection
)
ORDER BY f.profit_status, f.total_returns DESC;
