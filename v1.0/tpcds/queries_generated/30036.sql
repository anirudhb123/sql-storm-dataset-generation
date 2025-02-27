
WITH RECURSIVE SalesCTE AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_paid) AS total_sales
    FROM web_sales
    GROUP BY ws_sold_date_sk, ws_item_sk
    
    UNION ALL
    
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_paid) AS total_sales
    FROM web_sales ws
    JOIN SalesCTE cte ON ws_item_sk = cte.ws_item_sk
    WHERE ws_sold_date_sk > cte.ws_sold_date_sk
    GROUP BY ws_sold_date_sk, ws_item_sk
),
CustomerReturns AS (
    SELECT 
        sr_item_sk,
        SUM(sr_return_quantity) AS total_returns,
        SUM(sr_return_amt) AS total_return_amt
    FROM store_returns
    GROUP BY sr_item_sk
),
SalesWithReturns AS (
    SELECT 
        s.ws_item_sk,
        s.total_quantity,
        s.total_sales,
        COALESCE(r.total_returns, 0) AS total_returns,
        COALESCE(r.total_return_amt, 0) AS total_return_amt,
        ROW_NUMBER() OVER (PARTITION BY s.ws_item_sk ORDER BY s.total_sales DESC) AS sales_rank
    FROM SalesCTE s
    LEFT JOIN CustomerReturns r ON s.ws_item_sk = r.sr_item_sk
)
SELECT 
    i.i_item_id,
    i.i_item_desc,
    sw.total_quantity,
    sw.total_sales,
    sw.total_returns,
    sw.total_return_amt,
    CASE 
        WHEN sw.total_returns > 0 THEN 'Returned'
        ELSE 'Not Returned'
    END AS return_status
FROM SalesWithReturns sw
JOIN item i ON sw.ws_item_sk = i.i_item_sk
WHERE sw.sales_rank <= 10
ORDER BY sw.total_sales DESC;
