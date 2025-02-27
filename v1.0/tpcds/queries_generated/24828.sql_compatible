
WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk, 
        SUM(ws.ws_quantity) AS total_quantity, 
        SUM(ws.ws_net_profit) AS total_profit,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_net_profit) DESC) AS rank
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sales_price > 0 
        AND ws.ws_sold_date_sk BETWEEN 20230101 AND 20231231
    GROUP BY 
        ws.ws_item_sk
),
FilteredReturns AS (
    SELECT 
        sr.sr_item_sk,
        SUM(sr.sr_return_quantity) AS total_returns,
        COUNT(DISTINCT sr.sr_ticket_number) AS return_count
    FROM 
        store_returns sr
    WHERE 
        sr.sr_return_quantity > 0
    GROUP BY 
        sr.sr_item_sk
),
FinalResults AS (
    SELECT 
        it.i_item_id, 
        it.i_product_name,
        rs.total_quantity,
        rs.total_profit,
        COALESCE(fr.total_returns, 0) AS total_returns,
        COALESCE(fr.return_count, 0) AS return_count,
        CASE 
            WHEN rs.total_quantity = 0 THEN 'N/A'
            ELSE ROUND((COALESCE(fr.total_returns, 0) * 100.0) / rs.total_quantity, 2)
        END AS return_rate_percentage
    FROM 
        item it
    LEFT JOIN 
        RankedSales rs ON it.i_item_sk = rs.ws_item_sk
    LEFT JOIN 
        FilteredReturns fr ON it.i_item_sk = fr.sr_item_sk
    WHERE 
        rs.rank = 1
)
SELECT 
    *,
    CASE 
        WHEN total_profit IS NULL THEN 'Missing Profit'
        ELSE 'Profit Available'
    END AS profit_status
FROM 
    FinalResults 
WHERE 
    (total_returns > 0 OR return_rate_percentage > 10)
ORDER BY 
    return_rate_percentage DESC, 
    total_profit DESC;
