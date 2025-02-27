
WITH sales_data AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_profit) AS total_profit,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_net_profit) DESC) AS item_rank
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk
),
returns_data AS (
    SELECT 
        wr_item_sk,
        SUM(wr_return_quantity) AS total_returns
    FROM 
        web_returns
    GROUP BY 
        wr_item_sk
),
combined_sales AS (
    SELECT 
        sd.ws_item_sk,
        sd.total_quantity,
        sd.total_profit,
        COALESCE(rd.total_returns, 0) AS total_returns,
        sd.total_profit - COALESCE(rd.total_returns, 0) * (SELECT AVG(ws_net_profit) FROM web_sales) AS adjusted_profit
    FROM 
        sales_data sd
    LEFT JOIN 
        returns_data rd ON sd.ws_item_sk = rd.wr_item_sk
)
SELECT 
    cs.ws_item_sk,
    cs.total_quantity,
    cs.total_profit,
    cs.total_returns,
    cs.adjusted_profit,
    CASE 
        WHEN cs.adjusted_profit > 0 THEN 'Profitable'
        WHEN cs.adjusted_profit = 0 THEN 'Breaking Even'
        ELSE 'Loss'
    END AS profit_status
FROM 
    combined_sales cs
JOIN 
    item i ON cs.ws_item_sk = i.i_item_sk
WHERE 
    i.i_current_price IS NOT NULL
    AND cs.item_rank = 1
ORDER BY 
    cs.adjusted_profit DESC
LIMIT 10;
