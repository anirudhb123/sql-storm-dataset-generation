
WITH RankedSales AS (
    SELECT 
        ws.sale_date,
        ws.ws_item_sk,
        ws.ws_quantity,
        ws.ws_net_paid,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_net_paid DESC) AS sales_rank
    FROM 
        web_sales ws
    WHERE 
        ws.ws_net_paid > 0
),
ItemReturns AS (
    SELECT 
        wr.wr_item_sk,
        SUM(wr.wr_return_quantity) AS total_returned,
        SUM(wr.wr_return_amt) AS total_return_amount
    FROM 
        web_returns wr
    GROUP BY 
        wr.wr_item_sk
),
SalesWithReturns AS (
    SELECT 
        rs.sale_date,
        rs.ws_item_sk,
        rs.ws_quantity,
        rs.ws_net_paid,
        COALESCE(ir.total_returned, 0) AS total_returned,
        COALESCE(ir.total_return_amount, 0) AS total_return_amount
    FROM 
        RankedSales rs
    LEFT JOIN 
        ItemReturns ir ON rs.ws_item_sk = ir.wr_item_sk
)
SELECT 
    ws_item_sk,
    MAX(ws_quantity) AS max_quantity,
    SUM(ws_net_paid) AS total_sales,
    AVG(ws_net_paid) AS avg_sales,
    SUM(total_returned) AS total_returns,
    SUM(total_return_amount) AS total_return_amount,
    CASE 
        WHEN SUM(ws_net_paid) IS NULL THEN 'No Sales' 
        WHEN SUM(ws_net_paid) > 1000 THEN 'High Sales' 
        ELSE 'Regular Sales' 
    END AS sales_status
FROM 
    SalesWithReturns
WHERE 
    total_returned < max_quantity
GROUP BY 
    ws_item_sk
HAVING 
    SUM(ws_net_paid) IS NOT NULL
ORDER BY 
    total_sales DESC
LIMIT 10;
