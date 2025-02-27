
WITH RankedSales AS (
    SELECT
        ws.web_site_sk,
        ws.ws_order_number,
        ws.ws_sales_price,
        ROW_NUMBER() OVER (PARTITION BY ws.web_site_sk ORDER BY ws.ws_sales_price DESC) AS SalesRank
    FROM
        web_sales ws
    INNER JOIN
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE
        dd.d_year = 2023
),
CustomerReturns AS (
    SELECT 
        cr.returning_customer_sk,
        COUNT(DISTINCT cr.cr_order_number) AS TotalReturns,
        SUM(cr.cr_return_amount) AS TotalReturnAmount
    FROM 
        catalog_returns cr
    WHERE 
        cr.cr_returned_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        cr.returning_customer_sk
),
SalesAndReturns AS (
    SELECT 
        rs.web_site_sk,
        rs.ws_order_number,
        rs.ws_sales_price,
        COALESCE(cr.TotalReturns, 0) AS TotalReturns,
        COALESCE(cr.TotalReturnAmount, 0) AS TotalReturnAmount
    FROM 
        RankedSales rs
    LEFT JOIN 
        CustomerReturns cr ON rs.ws_order_number = cr.returning_customer_sk
)
SELECT 
    sa.web_site_sk,
    SUM(sa.ws_sales_price) AS TotalSales,
    SUM(sa.TotalReturns) AS TotalReturns,
    SUM(sa.TotalReturnAmount) AS TotalReturnAmount,
    CASE 
        WHEN SUM(sa.TotalReturns) = 0 THEN NULL 
        ELSE SUM(sa.ws_sales_price) / SUM(sa.TotalReturns) 
    END AS AverageReturnValue
FROM 
    SalesAndReturns sa
GROUP BY 
    sa.web_site_sk
ORDER BY 
    TotalSales DESC
LIMIT 10;
