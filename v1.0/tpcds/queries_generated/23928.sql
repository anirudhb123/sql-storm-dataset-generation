
WITH RankedReturns AS (
    SELECT 
        sr_item_sk,
        sr_return_quantity,
        sr_return_amt,
        ROW_NUMBER() OVER (PARTITION BY sr_item_sk ORDER BY sr_return_quantity DESC) AS rn
    FROM 
        store_returns 
    WHERE 
        sr_return_quantity IS NOT NULL
),
AggregateReturns AS (
    SELECT 
        rr.sr_item_sk,
        SUM(rr.sr_return_quantity) AS total_returned,
        AVG(rr.sr_return_amt) AS avg_return_amt
    FROM 
        RankedReturns rr
    WHERE 
        rr.rn <= 5
    GROUP BY 
        rr.sr_item_sk
),
WebSalesSummary AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_web_sales,
        COUNT(DISTINCT ws.ws_order_number) AS unique_orders
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_item_sk
),
SalesWithReturns AS (
    SELECT 
        wss.ws_item_sk,
        COALESCE(ar.total_returned, 0) AS total_returned,
        wss.total_web_sales,
        wss.unique_orders
    FROM 
        WebSalesSummary wss
    LEFT JOIN 
        AggregateReturns ar ON wss.ws_item_sk = ar.sr_item_sk
),
FinalReport AS (
    SELECT 
        s.warehouse_id,
        COUNT(DISTINCT cs.cs_order_number) AS total_catalog_sales,
        SUM(cs.cs_net_profit) AS total_net_profit,
        SUM(s.sales_price) AS total_sales_amount
    FROM 
        catalog_sales cs
    JOIN 
        inventory i ON cs.cs_item_sk = i.inv_item_sk
    JOIN 
        store s ON s.s_store_sk = (SELECT ss_store_sk FROM store_sales ss WHERE ss.ss_item_sk = cs.cs_item_sk LIMIT 1)
    WHERE 
        i.inv_quantity_on_hand > 0 AND 
        cs.cs_net_profit IS NOT NULL AND 
        s.s_closed_date_sk IS NULL
    GROUP BY 
        s.warehouse_id
)
SELECT 
    fr.warehouse_id,
    fr.total_catalog_sales,
    fr.total_net_profit,
    swr.total_web_sales,
    swr.total_returned,
    (CASE 
        WHEN fr.total_catalog_sales = 0 THEN NULL 
        ELSE (fr.total_net_profit / fr.total_catalog_sales) 
    END) AS profit_margin
FROM 
    FinalReport fr
LEFT JOIN 
    SalesWithReturns swr ON fr.warehouse_id = swr.ws_item_sk
WHERE 
    fr.total_catalog_sales > 100
ORDER BY 
    profit_margin DESC, fr.warehouse_id;
