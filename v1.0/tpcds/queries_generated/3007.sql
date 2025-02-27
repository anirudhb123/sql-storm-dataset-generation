
WITH SalesData AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_profit) AS total_net_profit,
        DENSE_RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_net_profit) DESC) AS profit_rank
    FROM 
        web_sales ws
    JOIN 
        item i ON ws.ws_item_sk = i.i_item_sk
    WHERE 
        i.i_current_price > 10 AND 
        ws.ws_sold_date_sk BETWEEN 20220101 AND 20221231 
    GROUP BY 
        ws.ws_item_sk
),
TopProfitableItems AS (
    SELECT 
        sd.ws_item_sk,
        sd.total_quantity,
        sd.total_net_profit
    FROM 
        SalesData sd
    WHERE 
        sd.profit_rank <= 10
),
ReturnsData AS (
    SELECT 
        cr.cr_item_sk,
        SUM(cr.cr_return_quantity) AS total_return_quantity,
        SUM(cr.cr_return_amt) AS total_return_amount
    FROM 
        catalog_returns cr
    WHERE 
        cr.cr_returned_date_sk BETWEEN 20220101 AND 20221231 
    GROUP BY 
        cr.cr_item_sk
)
SELECT 
    ti.ws_item_sk,
    ti.total_quantity,
    ti.total_net_profit,
    COALESCE(td.total_return_quantity, 0) AS total_return_quantity,
    COALESCE(td.total_return_amount, 0) AS total_return_amount,
    (ti.total_net_profit - COALESCE(td.total_return_amount, 0)) AS net_gain_loss
FROM 
    TopProfitableItems ti
LEFT JOIN 
    ReturnsData td ON ti.ws_item_sk = td.cr_item_sk
ORDER BY 
    net_gain_loss DESC;
