
WITH RankedSales AS (
    SELECT 
        ws_item_sk,
        SUM(ws_sales_price) AS total_sales,
        RANK() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_sales_price) DESC) AS sales_rank
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN 2451545 AND 2451547 -- Filter for a specific date range
    GROUP BY 
        ws_item_sk
),
TopSellingItems AS (
    SELECT 
        rs.ws_item_sk,
        i.i_item_desc,
        i.i_brand,
        i.i_category,
        rs.total_sales
    FROM 
        RankedSales rs
    JOIN 
        item i ON rs.ws_item_sk = i.i_item_sk
    WHERE 
        rs.sales_rank = 1
),
CustomerReturns AS (
    SELECT 
        sr_item_sk,
        COUNT(DISTINCT sr_ticket_number) AS total_returns,
        SUM(sr_return_amt) AS total_return_amount,
        SUM(sr_return_qty) AS total_return_qty
    FROM 
        store_returns
    GROUP BY 
        sr_item_sk
),
JoinSalesReturns AS (
    SELECT 
        tsi.wh_item_sk,
        tsi.i_item_desc,
        tsi.i_brand,
        tsi.i_category,
        tsi.total_sales,
        COALESCE(cr.total_returns, 0) AS total_returns,
        COALESCE(cr.total_return_amount, 0) AS total_return_amount,
        COALESCE(cr.total_return_qty, 0) AS total_return_qty
    FROM 
        TopSellingItems tsi
    LEFT JOIN 
        CustomerReturns cr ON tsi.ws_item_sk = cr.sr_item_sk
)
SELECT 
    j.ws_item_sk,
    j.i_item_desc,
    j.i_brand,
    j.i_category,
    j.total_sales,
    j.total_returns,
    j.total_return_amount,
    j.total_return_qty,
    CASE 
        WHEN j.total_returns > 0 THEN (j.total_return_qty * 100.0 / NULLIF(j.total_sales, 0))
        ELSE 0
    END AS return_rate
FROM 
    JoinSalesReturns j
ORDER BY 
    j.total_sales DESC
LIMIT 10;
