
WITH CustomerReturns AS (
    SELECT 
        sr_returned_date_sk,
        sr_return_time_sk,
        sr_item_sk,
        sr_return_quantity,
        sr_return_amt,
        sr_customer_sk
    FROM store_returns
    WHERE sr_return_quantity > 0
),
WebReturns AS (
    SELECT 
        wr_returned_date_sk,
        wr_returned_time_sk,
        wr_item_sk,
        wr_return_quantity,
        wr_return_amt,
        wr_returning_customer_sk
    FROM web_returns
    WHERE wr_return_quantity > 0
),
TotalReturns AS (
    SELECT
        COALESCE(csr.sr_item_sk, wwr.wr_item_sk) AS item_sk,
        COALESCE(csr.sr_return_quantity, 0) AS store_return_quantity,
        COALESCE(wwr.wr_return_quantity, 0) AS web_return_quantity,
        (COALESCE(csr.sr_return_quantity, 0) + COALESCE(wwr.wr_return_quantity, 0)) AS total_return_quantity
    FROM CustomerReturns csr
    FULL OUTER JOIN WebReturns wwr ON csr.sr_item_sk = wwr.wr_item_sk
),
ItemSales AS (
    SELECT 
        ws_item_sk,
        SUM(ws_sales_price) AS total_sales,
        COUNT(ws_order_number) AS total_orders
    FROM web_sales
    WHERE ws_sold_date_sk >= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY ws_item_sk
)
SELECT 
    i.i_item_id,
    i.i_item_desc,
    COALESCE(tr.total_return_quantity, 0) AS total_return_quantity,
    COALESCE(isales.total_sales, 0) AS total_sales,
    CASE 
        WHEN COALESCE(isales.total_sales, 0) = 0 THEN NULL
        ELSE (COALESCE(tr.total_return_quantity, 0) / isales.total_sales::decimal) * 100
    END AS return_percentage
FROM item i
LEFT JOIN TotalReturns tr ON i.i_item_sk = tr.item_sk
LEFT JOIN ItemSales isales ON i.i_item_sk = isales.ws_item_sk
WHERE 
    (COALESCE(tr.total_return_quantity, 0) > 5 OR COALESCE(isales.total_sales, 0) > 1000)
    AND (i.i_current_price IS NOT NULL)
ORDER BY return_percentage DESC
LIMIT 10;
