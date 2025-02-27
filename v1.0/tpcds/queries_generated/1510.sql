
WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk, 
        ws.ws_order_number, 
        ws.ws_sales_price, 
        ws.ws_quantity, 
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sales_price DESC) as rn 
    FROM 
        web_sales ws 
    WHERE 
        ws.ws_sales_price > 0 
        AND ws.ws_quantity > 0
),
CustomerReturns AS (
    SELECT 
        wr.wr_order_number, 
        wr.wr_item_sk, 
        SUM(wr.wr_return_quantity) AS total_returned 
    FROM 
        web_returns wr 
    WHERE 
        wr.wr_return_quantity IS NOT NULL 
    GROUP BY 
        wr.wr_order_number, wr.wr_item_sk
),
SalesSummary AS (
    SELECT 
        i.i_item_sk, 
        COALESCE(SUM(ss.ss_net_profit), 0) AS total_store_net_profit,
        COALESCE(SUM(cs.cs_net_profit), 0) AS total_catalog_net_profit,
        COALESCE(SUM(ws.ws_net_profit), 0) AS total_web_net_profit
    FROM 
        item i
    LEFT JOIN 
        store_sales ss ON i.i_item_sk = ss.ss_item_sk
    LEFT JOIN 
        catalog_sales cs ON i.i_item_sk = cs.cs_item_sk
    LEFT JOIN 
        web_sales ws ON i.i_item_sk = ws.ws_item_sk
    GROUP BY 
        i.i_item_sk
)
SELECT 
    s.i_item_id, 
    s.total_store_net_profit, 
    s.total_catalog_net_profit, 
    s.total_web_net_profit, 
    COALESCE(cr.total_returned, 0) AS total_returns,
    r.ws_sales_price AS highest_price
FROM 
    SalesSummary s
LEFT JOIN 
    CustomerReturns cr ON s.i_item_sk = cr.wr_item_sk
JOIN 
    RankedSales r ON s.i_item_sk = r.ws_item_sk AND r.rn = 1
WHERE 
    s.total_store_net_profit > (SELECT AVG(total_store_net_profit) FROM SalesSummary)
ORDER BY 
    s.total_store_net_profit DESC
LIMIT 10;
