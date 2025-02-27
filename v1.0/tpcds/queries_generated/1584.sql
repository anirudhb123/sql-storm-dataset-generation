
WITH RankedSales AS (
    SELECT 
        ws.web_site_sk,
        ws_sold_date_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws.web_site_sk ORDER BY SUM(ws_ext_sales_price) DESC) AS sales_rank
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2023
    GROUP BY 
        ws.web_site_sk, ws_sold_date_sk
),
CustomerReturns AS (
    SELECT 
        wr_returning_customer_sk,
        COUNT(*) AS total_returns,
        SUM(wr_return_amt_inc_tax) AS total_return_amount
    FROM 
        web_returns
    GROUP BY 
        wr_returning_customer_sk
),
TopCustomers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        COALESCE(SUM(ws.ws_ext_sales_price), 0) AS total_spent,
        COALESCE(SUM(cr.cr_return_amount), 0) AS total_returned
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN 
        catalog_returns cr ON c.c_customer_sk = cr.cr_refunded_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
    HAVING 
        total_spent > 500 OR total_returned > 100
)
SELECT 
    tc.c_customer_sk,
    tc.c_first_name,
    tc.c_last_name,
    tc.total_spent,
    tc.total_returned,
    rs.web_site_sk,
    rs.total_sales,
    CASE 
        WHEN tc.total_returned > 0 THEN (tc.total_returned::decimal / NULLIF(tc.total_spent, 0)) * 100
        ELSE 0
    END AS return_percentage
FROM 
    TopCustomers tc
JOIN 
    RankedSales rs ON tc.total_spent > (SELECT AVG(total_sales) FROM RankedSales)
LEFT JOIN 
    CustomerReturns cr ON tc.c_customer_sk = cr.wr_returning_customer_sk
ORDER BY 
    return_percentage DESC,
    total_spent DESC;
