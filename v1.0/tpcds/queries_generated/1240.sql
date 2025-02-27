
WITH CustomerReturns AS (
    SELECT 
        c.c_customer_id, 
        COUNT(sr_returned_date_sk) AS return_count,
        SUM(sr_return_amt) AS total_return_amt
    FROM 
        customer c
    LEFT JOIN 
        store_returns sr ON c.c_customer_sk = sr.sr_customer_sk
    GROUP BY 
        c.c_customer_id
),
TopReturningCustomers AS (
    SELECT 
        c.c_customer_id, 
        cr.return_count, 
        cr.total_return_amt,
        RANK() OVER (ORDER BY cr.total_return_amt DESC) AS rnk
    FROM 
        CustomerReturns cr
    JOIN 
        customer c ON c.c_customer_id = cr.c_customer_id
    WHERE 
        cr.return_count > 5
),
SalesInfo AS (
    SELECT 
        cs.cs_ship_date_sk, 
        SUM(cs.cs_sales_price) AS total_sales,
        COUNT(DISTINCT cs.cs_order_number) AS order_count
    FROM 
        catalog_sales cs
    JOIN 
        CustomerReturns cr ON cs.cs_bill_customer_sk = cr.c_customer_id
    GROUP BY 
        cs.cs_ship_date_sk
),
DailySales AS (
    SELECT 
        dd.d_date_id, 
        si.total_sales, 
        si.order_count,
        ROW_NUMBER() OVER (ORDER BY dd.d_date_id) AS sales_rank
    FROM 
        date_dim dd
    LEFT JOIN 
        SalesInfo si ON dd.d_date_sk = si.cs_ship_date_sk
)
SELECT 
    t.CustomerID,
    t.return_count,
    t.total_return_amt,
    ds.d_date_id,
    ds.total_sales,
    ds.order_count
FROM 
    TopReturningCustomers t
LEFT JOIN 
    DailySales ds ON t.return_count = ds.sales_rank
WHERE 
    (ds.total_sales IS NOT NULL AND ds.order_count > 0)
    OR (t.total_return_amt IS NULL)
ORDER BY 
    t.total_return_amt DESC, ds.d_date_id ASC;
