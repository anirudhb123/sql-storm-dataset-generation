
WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_sales_price,
        ws.ws_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_net_profit DESC) AS sales_rank
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk BETWEEN 1000 AND 2000
),
HighProfitItems AS (
    SELECT 
        item.i_item_sk,
        item.i_item_id,
        item.i_product_name,
        COALESCE(rs.sales_count, 0) AS total_sales,
        COALESCE(SUM(rs.ws_net_profit), 0) AS total_profit
    FROM 
        item
    LEFT JOIN (
        SELECT 
            ws.ws_item_sk,
            COUNT(*) AS sales_count,
            SUM(ws.ws_net_profit) AS ws_net_profit
        FROM 
            web_sales ws
        WHERE 
            ws.ws_net_profit > 1000
        GROUP BY 
            ws.ws_item_sk
    ) rs ON item.i_item_sk = rs.ws_item_sk
    GROUP BY 
        item.i_item_sk,
        item.i_item_id,
        item.i_product_name
    HAVING 
        SUM(COALESCE(rs.ws_net_profit, 0)) > 5000
),
CustomerReturns AS (
    SELECT 
        sr.sr_item_sk,
        COUNT(*) AS return_count,
        SUM(sr.sr_return_amt) AS total_return_amount
    FROM 
        store_returns sr
    WHERE 
        sr.sr_returned_date_sk BETWEEN 1000 AND 2000
    GROUP BY 
        sr.sr_item_sk
),
FinalResults AS (
    SELECT 
        hpi.i_item_id,
        hpi.i_product_name,
        hpi.total_sales,
        hpi.total_profit,
        cr.return_count
    FROM 
        HighProfitItems hpi
    LEFT JOIN CustomerReturns cr ON hpi.i_item_sk = cr.sr_item_sk
)
SELECT 
    fr.i_item_id,
    fr.i_product_name,
    fr.total_sales,
    fr.total_profit,
    COALESCE(fr.return_count, 0) AS return_count,
    CASE 
        WHEN fr.return_count > 0 THEN 'High Risk' 
        ELSE 'Low Risk' 
    END AS risk_category
FROM 
    FinalResults fr
ORDER BY 
    fr.total_profit DESC;
