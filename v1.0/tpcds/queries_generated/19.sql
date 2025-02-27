
WITH CustomerReturns AS (
    SELECT 
        wr_returned_date_sk, 
        wr_item_sk, 
        wr_return_quantity,
        wr_return_amt,
        wr_return_tax,
        wr_return_amt_inc_tax,
        wr_refunded_cash,
        wr_returning_customer_sk,
        wr_return_number,
        RANK() OVER (PARTITION BY wr_returning_customer_sk ORDER BY wr_returned_date_sk DESC) AS recent_return_rank
    FROM web_returns
    WHERE wr_return_quantity > 0
),
CatalogSalesData AS (
    SELECT 
        cs_item_sk,
        SUM(cs_quantity) AS total_sold_quantity,
        SUM(cs_ext_sales_price) AS total_sales_price
    FROM catalog_sales
    GROUP BY cs_item_sk
),
ReturnAggregate AS (
    SELECT 
        cr.wr_item_sk,
        SUM(cr.wr_return_quantity) AS total_returned_quantity,
        SUM(cr.wr_return_amt_inc_tax) AS total_returned_amt
    FROM CustomerReturns cr
    WHERE cr.recent_return_rank <= 5
    GROUP BY cr.wr_item_sk
),
ItemSummary AS (
    SELECT 
        i.i_item_sk,
        i.i_item_desc,
        COALESCE(cs.total_sold_quantity, 0) AS total_sold,
        COALESCE(ra.total_returned_quantity, 0) AS total_returned,
        COALESCE(ra.total_returned_amt, 0) AS total_returned_amt,
        i.i_current_price,
        (COALESCE(cs.total_sold_quantity, 0) - COALESCE(ra.total_returned_quantity, 0)) AS net_sales
    FROM item i
    LEFT JOIN CatalogSalesData cs ON i.i_item_sk = cs.cs_item_sk
    LEFT JOIN ReturnAggregate ra ON i.i_item_sk = ra.wr_item_sk
)
SELECT 
    i.i_item_desc,
    i.total_sold,
    i.total_returned,
    i.total_returned_amt,
    i.i_current_price,
    i.net_sales,
    (100.0 * i.total_returned / NULLIF(i.total_sold, 0)) AS return_rate
FROM ItemSummary i
WHERE i.net_sales > 0
ORDER BY return_rate DESC
LIMIT 10;
