
WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_ext_sales_price,
        RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_ext_sales_price DESC) AS sales_rank
    FROM 
        web_sales ws
    WHERE 
        ws.ws_ext_sales_price IS NOT NULL
),
StoreReturns AS (
    SELECT 
        sr_item_sk,
        SUM(sr_return_quantity) AS total_return_quantity,
        COUNT(DISTINCT sr_ticket_number) AS return_count,
        SUM(COALESCE(sr_return_amt, 0)) AS total_return_amt
    FROM 
        store_returns
    GROUP BY 
        sr_item_sk
),
CorrelatedReturns AS (
    SELECT 
        ir.ws_item_sk,
        COALESCE(SUM(sr.total_return_quantity), 0) AS total_store_returns,
        COALESCE(SUM(ir.ws_ext_sales_price - sr.total_return_amt), 0) AS net_sales_after_returns
    FROM 
        (SELECT DISTINCT ws_item_sk, ws_ext_sales_price FROM web_sales) ir
    LEFT JOIN 
        StoreReturns sr ON ir.ws_item_sk = sr.sr_item_sk
    GROUP BY 
        ir.ws_item_sk
),
FinalSales AS (
    SELECT 
        c.ws_item_sk,
        c.total_store_returns,
        c.net_sales_after_returns,
        COALESCE(r.sales_rank, 0) AS sales_rank,
        CASE 
            WHEN c.net_sales_after_returns > 0 THEN 'Profitable'
            WHEN c.net_sales_after_returns < 0 THEN 'Loss'
            ELSE 'Break-even' 
        END AS sales_status
    FROM 
        CorrelatedReturns c
    LEFT JOIN 
        RankedSales r ON c.ws_item_sk = r.ws_item_sk
)
SELECT 
    f.ws_item_sk,
    f.total_store_returns,
    f.net_sales_after_returns,
    f.sales_rank,
    f.sales_status,
    ROW_NUMBER() OVER (PARTITION BY f.sales_status ORDER BY f.net_sales_after_returns DESC) AS status_rank
FROM 
    FinalSales f
WHERE 
    f.net_sales_after_returns IS NOT NULL
ORDER BY 
    f.sales_status, f.net_sales_after_returns DESC
LIMIT 100
OFFSET (SELECT COUNT(*) FROM FinalSales) * RANDOM();
