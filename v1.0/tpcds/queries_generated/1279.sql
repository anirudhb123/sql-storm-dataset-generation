
WITH RankedSales AS (
    SELECT 
        ws.order_number,
        ws.item_sk,
        ws_sales_price,
        ws_ext_sales_price,
        ROW_NUMBER() OVER (PARTITION BY ws.order_number ORDER BY ws.sales_price DESC) AS rn
    FROM 
        web_sales ws
    WHERE 
        ws_sales_price > (SELECT AVG(ws_sales_price) FROM web_sales WHERE ws_ship_date_sk > 0)
),
CustomerReturns AS (
    SELECT 
        sr.returned_date_sk,
        sr.return_time_sk,
        sr.return_quantity,
        sr.return_amt,
        ws.customer_sk,
        COALESCE(sr.return_quantity, 0) AS total_returned,
        SUM(NULLIF(sr.return_amt, 0)) OVER (PARTITION BY sr.customer_sk) AS total_return_amount
    FROM 
        store_returns sr
    LEFT JOIN 
        web_sales ws ON sr.item_sk = ws.item_sk AND sr.customer_sk = ws.bill_customer_sk
),
DailySales AS (
    SELECT 
        dd.d_date,
        SUM(ws.net_paid) AS total_sales,
        COUNT(DISTINCT ws.order_number) AS orders_count
    FROM 
        date_dim dd
    LEFT JOIN 
        web_sales ws ON dd.d_date_sk = ws.sold_date_sk
    WHERE 
        dd.d_year = 2023 AND dd.d_month_seq BETWEEN 1 AND 3
    GROUP BY 
        dd.d_date
)
SELECT 
    d.d_date,
    ds.total_sales,
    ds.orders_count,
    COALESCE(cr.total_return_amount, 0) AS total_returns,
    ds.total_sales - COALESCE(cr.total_return_amount, 0) AS net_sales,
    RANK() OVER (ORDER BY ds.total_sales DESC) AS sales_rank
FROM 
    DailySales ds
LEFT JOIN 
    CustomerReturns cr ON ds.orders_count = cr.total_returned
JOIN 
    date_dim d ON d.d_date_sk = ds.sold_date_sk
WHERE 
    d.d_current_month = 'Y'
ORDER BY 
    d.d_date;
