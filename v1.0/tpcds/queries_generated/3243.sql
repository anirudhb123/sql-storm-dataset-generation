
WITH CustomerReturns AS (
    SELECT 
        sr.returned_date_sk,
        sr.store_sk,
        COUNT(*) AS total_returns,
        SUM(sr.return_amt_inc_tax) AS total_return_amount,
        AVG(sr.return_quantity) AS avg_return_quantity
    FROM 
        store_returns sr
    GROUP BY 
        sr.returned_date_sk, sr.store_sk
),
WebSalesData AS (
    SELECT 
        ws_ship_date_sk,
        SUM(ws_sales_price) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS total_orders
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN 24710 AND 24780 -- Arbitrary date range
    GROUP BY 
        ws_ship_date_sk
),
SalesPerformance AS (
    SELECT 
        d.d_date AS sales_date,
        COALESCE(cr.total_returns, 0) AS total_returns,
        COALESCE(ws.total_sales, 0) AS total_sales,
        ws.total_orders
    FROM 
        date_dim d
    LEFT JOIN 
        CustomerReturns cr ON d.d_date_sk = cr.returned_date_sk
    FULL OUTER JOIN 
        WebSalesData ws ON d.d_date_sk = ws.ws_ship_date_sk
    WHERE 
        d.d_year = 2021 -- An arbitrary year of interest
)
SELECT 
    sp.sales_date,
    sp.total_returns,
    sp.total_sales,
    sp.total_orders,
    (CASE 
        WHEN sp.total_sales > 0 THEN ROUND((sp.total_returns::decimal / sp.total_sales) * 100, 2)
        ELSE NULL 
    END) AS return_rate_percentage,
    ROW_NUMBER() OVER (ORDER BY sp.sales_date) AS row_num,
    RANK() OVER (ORDER BY sp.total_sales DESC) AS sales_rank
FROM 
    SalesPerformance sp
WHERE 
    sp.total_sales IS NOT NULL
ORDER BY 
    sp.sales_date;
