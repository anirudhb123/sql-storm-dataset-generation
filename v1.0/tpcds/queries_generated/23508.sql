
WITH RankedSales AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity_sold,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_sales_price) DESC) AS rn
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk
),
TotalReturns AS (
    SELECT 
        wr_item_sk AS item_sk,
        SUM(wr_return_quantity) AS total_returned
    FROM 
        web_returns
    GROUP BY 
        wr_item_sk
),
HighReturnItems AS (
    SELECT 
        tr.item_sk
    FROM 
        TotalReturns tr
    WHERE 
        tr.total_returned > (SELECT AVG(total_returned) FROM TotalReturns)
),
SalesWithReturns AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_sales_price,
        rs.total_quantity_sold,
        COALESCE(tr.total_returned, 0) AS total_returned,
        CASE 
            WHEN tr.item_sk IS NOT NULL THEN 'High Return'
            ELSE 'Normal'
        END AS return_status
    FROM 
        web_sales ws
    JOIN 
        RankedSales rs ON ws.ws_item_sk = rs.ws_item_sk
    LEFT JOIN 
        HighReturnItems tr ON ws.ws_item_sk = tr.item_sk
    WHERE 
        ws.ws_sold_date_sk BETWEEN 2000000 AND 2000200 
)

SELECT 
    s.item_sk,
    s.total_quantity_sold,
    s.ws_sales_price,
    s.total_returned,
    s.return_status,
    CASE 
        WHEN s.return_status = 'High Return' THEN s.total_quantity_sold / NULLIF(s.total_returned, 0) 
        ELSE s.total_quantity_sold 
    END AS adjusted_quantity_sold,
    STRING_AGG(DISTINCT CONCAT('Item ', s.item_sk, ' sold at price ', s.ws_sales_price), ', ') 
        FILTER (WHERE s.return_status = 'High Return') AS high_return_items_info
FROM 
    SalesWithReturns s
WHERE 
    s.total_quantity_sold > 100
GROUP BY 
    s.item_sk, s.total_quantity_sold, s.ws_sales_price, s.total_returned, s.return_status
ORDER BY 
    adjusted_quantity_sold DESC
LIMIT 50;
