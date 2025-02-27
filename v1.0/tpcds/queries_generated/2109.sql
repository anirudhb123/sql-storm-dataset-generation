
WITH RankedSales AS (
    SELECT 
        ws_item_sk, 
        ws_order_number, 
        ws_sales_price,
        ws_net_paid,
        RANK() OVER (PARTITION BY ws_item_sk ORDER BY ws_net_paid DESC) AS rank_sales
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN 1 AND 365
),
StoreReturns AS (
    SELECT 
        sr_item_sk, 
        SUM(sr_return_quantity) AS total_returns
    FROM 
        store_returns
    WHERE 
        sr_returned_date_sk BETWEEN 1 AND 365
    GROUP BY 
        sr_item_sk
),
HighVolumeItems AS (
    SELECT 
        i_item_sk,
        SUM(ws_quantity) AS total_sold_quantity
    FROM 
        web_sales 
    GROUP BY 
        i_item_sk
    HAVING 
        SUM(ws_quantity) > 1000
)
SELECT 
    i.i_item_id,
    COALESCE(r.total_returns, 0) AS total_returns,
    COALESCE(s.total_sold_quantity, 0) AS total_sold_quantity,
    SUM(CASE WHEN r.rank_sales = 1 THEN ws_sales_price END) AS highest_price
FROM 
    item i
LEFT JOIN 
    RankedSales r ON i.i_item_sk = r.ws_item_sk
LEFT JOIN 
    StoreReturns sr ON i.i_item_sk = sr.sr_item_sk
LEFT JOIN 
    HighVolumeItems s ON i.i_item_sk = s.i_item_sk
WHERE 
    i.i_current_price > (SELECT AVG(i_current_price) FROM item)
GROUP BY 
    i.i_item_id, r.total_returns, s.total_sold_quantity
ORDER BY 
    total_sold_quantity DESC, highest_price DESC
LIMIT 100;
