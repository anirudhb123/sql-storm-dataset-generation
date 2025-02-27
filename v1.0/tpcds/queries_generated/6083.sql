
WITH RankedReturns AS (
    SELECT 
        sr_returned_date_sk,
        sr_item_sk,
        COUNT(*) AS total_returns,
        SUM(sr_return_amt) AS total_return_amount,
        SUM(sr_return_quantity) AS total_return_quantity,
        RANK() OVER (PARTITION BY sr_item_sk ORDER BY SUM(sr_return_amt) DESC) AS return_rank
    FROM 
        store_returns
    GROUP BY 
        sr_returned_date_sk, sr_item_sk
), ProductSales AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_sales_quantity,
        SUM(ws_sales_price) AS total_sales_amount
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN 1000 AND 2000 -- assuming these are valid date keys
    GROUP BY 
        ws_item_sk
), CombinedData AS (
    SELECT 
        p.ws_item_sk,
        COALESCE(r.total_returns, 0) AS total_returns,
        COALESCE(r.total_return_quantity, 0) AS total_return_quantity,
        COALESCE(r.total_return_amount, 0) AS total_return_amount,
        COALESCE(s.total_sales_quantity, 0) AS total_sales_quantity,
        COALESCE(s.total_sales_amount, 0) AS total_sales_amount
    FROM 
        ProductSales s
    LEFT JOIN 
        RankedReturns r ON s.ws_item_sk = r.sr_item_sk
)
SELECT 
    c.ws_item_sk,
    total_returns,
    total_return_quantity,
    total_return_amount,
    total_sales_quantity,
    total_sales_amount,
    (total_sales_amount - total_return_amount) AS net_sales,
    CASE 
        WHEN total_sales_quantity > 0 THEN (total_returns::decimal / total_sales_quantity) * 100
        ELSE 0 
    END AS return_rate_percentage
FROM 
    CombinedData c
ORDER BY 
    net_sales DESC
LIMIT 50;
