
WITH RankedSales AS (
    SELECT 
        s_store_sk, 
        SUM(ws_ext_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY s_store_sk ORDER BY SUM(ws_ext_sales_price) DESC) AS sales_rank
    FROM 
        web_sales 
    JOIN store ON web_sales.ws_store_sk = store.s_store_sk
    GROUP BY s_store_sk
),
SalesDetails AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_item_sk,
        ws.ws_web_site_sk,
        ws.ws_sales_price,
        ws.ws_quantity,
        COALESCE(NULLIF(ws.ws_ext_discount_amt, 0), NULL) AS discount_applied,
        COALESCE(NULLIF(ws.ws_net_profit, 0), NULL) AS net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_order_number ORDER BY ws.ws_quantity DESC) as quantity_rank
    FROM 
        web_sales ws 
    WHERE 
        ws.ws_sales_price > (SELECT AVG(ws2.ws_sales_price) FROM web_sales ws2 WHERE ws2.ws_web_site_sk = ws.ws_web_site_sk)
),
StoreReturns AS (
    SELECT 
        sr.store_sk,
        SUM(sr.returned_quantity) AS total_returns
    FROM 
        (SELECT 
            sr_store_sk AS store_sk, 
            SUM(sr_return_quantity) AS returned_quantity
        FROM 
            store_returns 
        GROUP BY 
            sr_store_sk) sr
    GROUP BY sr.store_sk
)

SELECT 
    s.s_store_name,
    s.s_city,
    s.s_state,
    COALESCE(RS.total_sales, 0) AS total_sales,
    COALESCE(SR.total_returns, 0) AS total_returns,
    (COALESCE(RS.total_sales, 0) - COALESCE(SR.total_returns, 0)) AS net_sales_after_returns,
    CASE WHEN COALESCE(SR.total_returns, 0) > 0 THEN 'Returns Processed' ELSE 'No Returns' END AS return_status,
    (SELECT COUNT(*) FROM SalesDetails WHERE quantity_rank = 1) AS top_quantity_sales_count
FROM 
    store s
LEFT JOIN RankedSales RS ON s.s_store_sk = RS.s_store_sk
LEFT JOIN StoreReturns SR ON s.s_store_sk = SR.store_sk
WHERE 
    s.s_state IS NOT NULL 
    AND NOT (s.s_store_name IS NULL OR s.s_store_name = '')
    AND (RS.total_sales > 10000 OR SR.total_returns IS NOT NULL)
ORDER BY 
    net_sales_after_returns DESC
LIMIT 50;
