
WITH RECURSIVE SalesCTE (SalesDate, TotalSales) AS (
    SELECT d.d_date AS SalesDate, SUM(ws.ws_ext_sales_price) AS TotalSales
    FROM date_dim d
    JOIN web_sales ws ON d.d_date_sk = ws.ws_sold_date_sk
    WHERE d.d_year = 2023
    GROUP BY d.d_date
    UNION ALL
    SELECT DATEADD(DAY, 1, SalesDate), SUM(ws.ws_ext_sales_price)
    FROM SalesCTE
    JOIN web_sales ws ON SalesCTE.SalesDate = ws.ws_sold_date
    GROUP BY SalesDate
),
CustomerReturns AS (
    SELECT c.c_customer_sk, COALESCE(SUM(sr.sr_return_quantity), 0) AS TotalReturns
    FROM customer c
    LEFT JOIN store_returns sr ON c.c_customer_sk = sr.sr_customer_sk
    GROUP BY c.c_customer_sk
),
SalesWithReturns AS (
    SELECT c.c_customer_sk, SUM(ws.ws_ext_sales_price) AS TotalSales, cr.TotalReturns
    FROM customer c
    JOIN web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    LEFT JOIN CustomerReturns cr ON c.c_customer_sk = cr.c_customer_sk
    GROUP BY c.c_customer_sk, cr.TotalReturns
)
SELECT s.SalesDate, SUM(sw.TotalSales) AS PresentedSales, SUM(sw.TotalReturns) AS TotalReturns
FROM SalesCTE s
JOIN SalesWithReturns sw ON s.SalesDate = sw.SalesDate
WHERE sw.TotalReturns IS NOT NULL
GROUP BY s.SalesDate
ORDER BY s.SalesDate;
