
WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_sales_price,
        ws.ws_quantity,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sales_price DESC) AS rank_sales
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sales_price IS NOT NULL 
        AND ws.ws_quantity > 0
),
AggSales AS (
    SELECT 
        cs.cs_item_sk,
        SUM(cs.cs_quantity) AS total_quantity,
        COUNT(DISTINCT cs.cs_order_number) AS total_orders,
        AVG(cs.cs_sales_price) AS avg_sales_price
    FROM 
        catalog_sales cs
    WHERE 
        cs.cs_sales_price IS NOT NULL
        AND cs.cs_ship_date_sk > 0
    GROUP BY 
        cs.cs_item_sk
),
CustomerReturns AS (
    SELECT 
        sr.sr_item_sk,
        COUNT(sr.sr_ticket_number) AS total_returns,
        SUM(sr.sr_return_amt) AS total_return_amount
    FROM 
        store_returns sr
    WHERE 
        sr.sr_return_quantity IS NOT NULL
        AND sr.sr_item_sk IS NOT NULL
    GROUP BY 
        sr.sr_item_sk
),
CombinedSales AS (
    SELECT 
        rs.ws_item_sk,
        rs.ws_order_number,
        rs.ws_sales_price,
        as.total_quantity,
        as.total_orders,
        cr.total_returns,
        cr.total_return_amount,
        COALESCE(CASE WHEN cr.total_returns IS NULL THEN 0 ELSE cr.total_returns END, 0) AS adjusted_returns
    FROM 
        RankedSales rs
    LEFT JOIN 
        AggSales as ON rs.ws_item_sk = as.cs_item_sk
    LEFT JOIN 
        CustomerReturns cr ON rs.ws_item_sk = cr.sr_item_sk
)
SELECT 
    ws_item_sk,
    COUNT(ws_order_number) AS number_of_orders,
    SUM(ws_sales_price * total_quantity) AS total_sales_revenue,
    AVG(SUM(total_sales_revenue) OVER (PARTITION BY ws_item_sk)) AS avg_sales_per_item,
    COUNT(CASE WHEN adjusted_returns > 0 THEN 1 END) AS items_with_returns,
    STRING_AGG(DISTINCT CONCAT_WS('-', ws_order_number, total_quantity), '; ') AS order_details
FROM 
    CombinedSales
GROUP BY 
    ws_item_sk
HAVING 
    COUNT(ws_order_number) > 10
ORDER BY 
    avg_sales_per_item DESC,
    ws_item_sk
LIMIT 100;
