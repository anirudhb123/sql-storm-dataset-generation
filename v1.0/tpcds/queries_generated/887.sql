
WITH SalesData AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        SUM(ws.ws_net_profit) AS total_net_profit,
        COUNT(ws.ws_order_number) AS order_count,
        DENSE_RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_net_profit) DESC) AS profit_rank
    FROM 
        web_sales ws
    JOIN 
        item i ON ws.ws_item_sk = i.i_item_sk
    WHERE 
        ws.ws_sold_date_sk BETWEEN 1 AND 1000
    GROUP BY 
        ws.ws_item_sk, ws.ws_order_number
),
CustomerReturns AS (
    SELECT 
        wr_wr_item_sk,
        SUM(wr.return_quantity) AS total_return_quantity,
        AVG(wr.return_amt) AS avg_return_amount
    FROM 
        web_returns wr
    GROUP BY 
        wr_wr_item_sk
)
SELECT 
    i.i_item_id,
    i.i_product_name,
    COALESCE(sd.total_net_profit, 0) AS total_net_profit,
    COALESCE(cr.total_return_quantity, 0) AS total_return_quantity,
    COALESCE(cr.avg_return_amount, 0) AS avg_return_amount,
    CASE 
        WHEN sd.profit_rank = 1 THEN 'Top Performer'
        ELSE 'Other'
    END AS performance_category
FROM 
    item i
LEFT JOIN 
    SalesData sd ON i.i_item_sk = sd.ws_item_sk
LEFT JOIN 
    CustomerReturns cr ON i.i_item_sk = cr.wr_wr_item_sk
WHERE 
    i.i_current_price IS NOT NULL
    AND (cr.total_return_quantity > 0 OR sd.total_net_profit > 1000)
ORDER BY 
    total_net_profit DESC,
    total_return_quantity ASC;
