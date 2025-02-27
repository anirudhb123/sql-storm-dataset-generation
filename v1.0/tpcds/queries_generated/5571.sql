
WITH CustomerReturns AS (
    SELECT 
        wr.returned_date_sk AS ReturnDate,
        COUNT(DISTINCT wr.returning_customer_sk) AS UniqueReturningCustomers,
        SUM(wr.return_amount) AS TotalReturnAmount,
        SUM(wr.return_tax) AS TotalReturnTax,
        SUM(wr.return_ship_cost) AS TotalReturnShippingCost
    FROM 
        web_returns wr
    GROUP BY 
        wr.returned_date_sk
),
SalesSummary AS (
    SELECT 
        ws.sold_date_sk AS SaleDate,
        COUNT(DISTINCT ws.bill_customer_sk) AS UniquePurchasingCustomers,
        SUM(ws.ext_sales_price) AS TotalSales,
        SUM(ws.ext_discount_amt) AS TotalDiscounts,
        SUM(ws.ext_tax) AS TotalSalesTax
    FROM 
        web_sales ws
    GROUP BY 
        ws.sold_date_sk
),
AggregatedData AS (
    SELECT 
        dd.d_date AS Date,
        COALESCE(cr.UniqueReturningCustomers, 0) AS UniqueReturningCustomers,
        COALESCE(ss.UniquePurchasingCustomers, 0) AS UniquePurchasingCustomers,
        COALESCE(cr.TotalReturnAmount, 0) AS TotalReturnAmount,
        COALESCE(ss.TotalSales, 0) AS TotalSales,
        COALESCE(cr.TotalReturnTax, 0) AS TotalReturnTax,
        COALESCE(ss.TotalDiscounts, 0) AS TotalDiscounts,
        COALESCE(cr.TotalReturnShippingCost, 0) AS TotalReturnShippingCost,
        COALESCE(ss.TotalSalesTax, 0) AS TotalSalesTax
    FROM 
        date_dim dd
    LEFT JOIN 
        CustomerReturns cr ON dd.d_date_sk = cr.ReturnDate
    LEFT JOIN 
        SalesSummary ss ON dd.d_date_sk = ss.SaleDate
)
SELECT 
    a.Date,
    a.UniqueReturningCustomers,
    a.UniquePurchasingCustomers,
    a.TotalReturnAmount,
    a.TotalSales,
    a.TotalReturnTax,
    a.TotalDiscounts,
    a.TotalReturnShippingCost,
    a.TotalSalesTax,
    (a.TotalSales - a.TotalReturnAmount) AS NetSales,
    (a.TotalSalesTax - a.TotalReturnTax) AS NetSalesTax
FROM 
    AggregatedData a
WHERE 
    a.Date BETWEEN DATE '2023-01-01' AND DATE '2023-12-31'
ORDER BY 
    a.Date;
