
WITH SalesData AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_profit) AS total_profit,
        COUNT(DISTINCT ws.ws_order_number) AS unique_orders,
        DENSE_RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_net_profit) DESC) AS profit_rank
    FROM 
        web_sales ws
    JOIN 
        item i ON ws.ws_item_sk = i.i_item_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year = 2023
    GROUP BY 
        ws.ws_item_sk
),
TopSellingItems AS (
    SELECT 
        i.i_item_id,
        i.i_item_desc,
        sd.total_quantity,
        sd.total_profit,
        sd.unique_orders
    FROM 
        SalesData sd
    JOIN 
        item i ON sd.ws_item_sk = i.i_item_sk
    WHERE 
        sd.profit_rank <= 10
)
SELECT 
    tsi.i_item_id,
    tsi.i_item_desc,
    tsi.total_quantity,
    tsi.total_profit,
    tsi.unique_orders,
    COALESCE(SUM(sr.sr_return_quantity), 0) AS total_returns,
    COALESCE(SUM(sr.sr_return_amt), 0) AS total_return_amount
FROM 
    TopSellingItems tsi
LEFT JOIN 
    store_returns sr ON tsi.i_item_id = sr.sr_item_sk
GROUP BY 
    tsi.i_item_id, tsi.i_item_desc, tsi.total_quantity, tsi.total_profit, tsi.unique_orders
ORDER BY 
    tsi.total_profit DESC;
