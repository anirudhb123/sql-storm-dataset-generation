
WITH CustomerReturns AS (
    SELECT 
        wr_returned_date_sk,
        wr_item_sk,
        wr_return_quantity,
        wr_return_amt,
        wr_return_tax,
        wr_order_number
    FROM web_returns
    WHERE wr_return_quantity > 0
),
StoreReturns AS (
    SELECT 
        sr_returned_date_sk,
        sr_item_sk,
        sr_return_quantity,
        sr_return_amt,
        sr_return_tax,
        sr_ticket_number
    FROM store_returns
    WHERE sr_return_quantity > 0
),
TotalReturns AS (
    SELECT 
        'Web' AS return_source,
        wr_returned_date_sk,
        SUM(wr_return_quantity) AS total_return_quantity,
        SUM(wr_return_amt) AS total_return_amt,
        SUM(wr_return_tax) AS total_return_tax
    FROM CustomerReturns
    GROUP BY wr_returned_date_sk
    
    UNION ALL

    SELECT 
        'Store' AS return_source,
        sr_returned_date_sk,
        SUM(sr_return_quantity) AS total_return_quantity,
        SUM(sr_return_amt) AS total_return_amt,
        SUM(sr_return_tax) AS total_return_tax
    FROM StoreReturns
    GROUP BY sr_returned_date_sk
),
SalesSummary AS (
    SELECT 
        d.d_date AS return_date,
        t.return_source,
        COALESCE(t.total_return_quantity, 0) AS total_return_quantity,
        COALESCE(t.total_return_amt, 0) AS total_return_amt,
        COALESCE(t.total_return_tax, 0) AS total_return_tax,
        SUM(ws_ext_sales_price) AS total_sales_amount,
        COUNT(ws_order_number) AS total_orders
    FROM date_dim d
    LEFT JOIN TotalReturns t ON d.d_date_sk = t.wr_returned_date_sk
    LEFT JOIN web_sales ws ON d.d_date_sk = ws.ws_sold_date_sk
    GROUP BY d.d_date, t.return_source
)

SELECT 
    s.return_date,
    s.return_source,
    s.total_return_quantity,
    s.total_return_amt,
    s.total_return_tax,
    s.total_sales_amount,
    s.total_orders,
    (CASE 
        WHEN s.total_sales_amount > 0 THEN (s.total_return_quantity::decimal / NULLIF(s.total_sales_amount, 0)) * 100 
        ELSE 0 
    END) AS return_rate_percentage
FROM SalesSummary s
WHERE s.total_return_quantity > 0
ORDER BY s.return_date, s.return_source;
