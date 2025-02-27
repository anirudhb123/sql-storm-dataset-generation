
WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_sales_price,
        ws.ws_quantity,
        ws.ws_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sales_price DESC) AS price_rank
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sales_price IS NOT NULL
),
ItemAverage AS (
    SELECT
        ir.i_item_sk,
        AVG(ir.i_current_price) AS avg_price
    FROM 
        item ir
    WHERE
        ir.i_rec_start_date <= CURRENT_DATE AND 
        (ir.i_rec_end_date > CURRENT_DATE OR ir.i_rec_end_date IS NULL)
    GROUP BY 
        ir.i_item_sk
),
HighValue AS (
    SELECT 
        rs.ws_item_sk,
        SUM(rs.ws_net_profit) AS total_net_profit
    FROM 
        RankedSales rs
    WHERE 
        rs.price_rank = 1
    GROUP BY 
        rs.ws_item_sk
    HAVING 
        SUM(rs.ws_net_profit) > (SELECT AVG(total_net_profit) FROM HighValue)
)
SELECT 
    i.i_item_id,
    i.i_item_desc,
    COALESCE(a.avg_price, 0) AS average_price,
    COALESCE(hvp.total_net_profit, 0) AS total_net_profit,
    CASE 
        WHEN COALESCE(hvp.total_net_profit, 0) > 0 THEN 'Profitable'
        ELSE 'Not Profitable'
    END AS profitability_status
FROM 
    item i
LEFT JOIN 
    ItemAverage a ON i.i_item_sk = a.i_item_sk
LEFT JOIN 
    HighValue hvp ON i.i_item_sk = hvp.ws_item_sk
WHERE 
    (i.i_size LIKE '%Medium%' OR i.i_color IS NULL)
ORDER BY 
    average_price DESC, 
    profitability_status ASC;
