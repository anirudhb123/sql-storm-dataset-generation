
WITH CustomerReturns AS (
    SELECT 
        sr.returned_date_sk AS ReturnDate,
        SUM(sr.return_quantity) AS TotalReturnQuantity,
        SUM(sr.return_amt) AS TotalReturnAmount,
        COUNT(DISTINCT sr.customer_sk) AS UniqueCustomersReturned
    FROM 
        store_returns sr
    WHERE 
        sr.returned_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023) 
        AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        sr.returned_date_sk
),

SalesPerformance AS (
    SELECT 
        ws_sold_date_sk AS SaleDate,
        SUM(ws_sales_price) AS TotalSalesAmount,
        COUNT(DISTINCT ws_order_number) AS TotalSalesCount,
        SUM(ws_quantity) AS TotalQuantitySold
    FROM 
        web_sales 
    WHERE 
        ws_sold_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023) 
        AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        ws_sold_date_sk
)

SELECT 
    d.d_date AS Date,
    COALESCE(cr.TotalReturnQuantity, 0) AS TotalReturnQuantity,
    COALESCE(cr.TotalReturnAmount, 0) AS TotalReturnAmount,
    COALESCE(sp.TotalSalesAmount, 0) AS TotalSalesAmount,
    COALESCE(sp.TotalSalesCount, 0) AS TotalSalesCount,
    COALESCE(sp.TotalQuantitySold, 0) AS TotalQuantitySold
FROM 
    date_dim d
LEFT JOIN 
    CustomerReturns cr ON d.d_date_sk = cr.ReturnDate
LEFT JOIN 
    SalesPerformance sp ON d.d_date_sk = sp.SaleDate
WHERE 
    d.d_year = 2023
ORDER BY 
    d.d_date;
