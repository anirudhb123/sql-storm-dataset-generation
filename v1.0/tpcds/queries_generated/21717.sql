
WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_ext_sales_price,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_ext_sales_price DESC) AS rank
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk BETWEEN (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2022) - 30 
        AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2022)
),
TotalReturns AS (
    SELECT 
        wr.wr_item_sk,
        SUM(wr.wr_return_quantity) AS total_returned
    FROM 
        web_returns wr
    GROUP BY 
        wr.wr_item_sk
),
SalesWithReturns AS (
    SELECT 
        rs.ws_item_sk,
        rs.ws_order_number,
        rs.ws_ext_sales_price,
        COALESCE(tr.total_returned, 0) AS total_returned
    FROM 
        RankedSales rs
    LEFT JOIN 
        TotalReturns tr ON rs.ws_item_sk = tr.wr_item_sk
)
SELECT 
    swr.ws_item_sk,
    COUNT(*) AS order_count,
    SUM(swr.ws_ext_sales_price) AS total_sales,
    AVG(swr.ws_ext_sales_price) AS avg_sales_price,
    MAX(swr.total_returned) AS max_returns,
    MIN(swr.total_returned) AS min_returns
FROM 
    SalesWithReturns swr
GROUP BY 
    swr.ws_item_sk
HAVING 
    SUM(swr.ws_ext_sales_price) > 1000
    AND COUNT(*) > 5
ORDER BY 
    SUM(swr.ws_ext_sales_price) DESC 
LIMIT 10 
OFFSET (SELECT COUNT(DISTINCT i_item_sk) FROM item WHERE i_rec_start_date < CURRENT_DATE) % 50
```
