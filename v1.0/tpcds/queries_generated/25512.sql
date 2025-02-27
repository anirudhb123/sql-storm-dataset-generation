
WITH RankedItems AS (
    SELECT 
        i.i_item_id,
        i.i_item_desc,
        i.i_brand,
        i.i_current_price,
        ROW_NUMBER() OVER (PARTITION BY i.i_brand ORDER BY i.i_current_price DESC) as price_rank
    FROM 
        item i
    WHERE 
        i.i_item_desc LIKE '%Premium%'
),
SalesSummary AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_profit) AS total_profit
    FROM 
        web_sales ws 
    JOIN 
        RankedItems r ON ws.ws_item_sk = r.i_item_id
    GROUP BY 
        ws.ws_item_sk
)
SELECT 
    r.i_item_desc,
    r.i_brand,
    r.i_current_price,
    ss.total_quantity,
    ss.total_profit
FROM 
    RankedItems r
JOIN 
    SalesSummary ss ON r.i_item_id = ss.ws_item_sk
WHERE 
    r.price_rank <= 5
ORDER BY 
    r.i_brand, ss.total_profit DESC;
