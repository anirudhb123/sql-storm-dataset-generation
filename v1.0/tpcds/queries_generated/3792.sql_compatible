
WITH RankedSales AS (
    SELECT 
        ws.web_site_sk,
        ws.web_name,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS order_count,
        RANK() OVER (PARTITION BY ws.web_site_sk ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS sales_rank
    FROM 
        web_sales ws
    GROUP BY 
        ws.web_site_sk, ws.web_name
),
CustomerReturns AS (
    SELECT 
        wr.returning_customer_sk,
        SUM(wr.wr_return_amt) AS total_return_amt,
        COUNT(wr.wr_order_number) AS return_count
    FROM 
        web_returns wr
    GROUP BY 
        wr.returning_customer_sk
),
TopCustomers AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        COALESCE(cr.total_return_amt, 0) AS total_return_amt,
        COALESCE(cr.return_count, 0) AS return_count,
        ROW_NUMBER() OVER (ORDER BY COALESCE(cr.total_return_amt, 0) DESC) AS return_rank
    FROM 
        customer c
    LEFT JOIN 
        CustomerReturns cr ON c.c_customer_sk = cr.returning_customer_sk
)
SELECT 
    rs.web_name,
    rs.total_sales,
    tc.c_customer_id,
    tc.c_first_name,
    tc.c_last_name,
    tc.total_return_amt,
    tc.return_count
FROM 
    RankedSales rs
LEFT JOIN 
    TopCustomers tc ON rs.web_site_sk = tc.c_customer_id
WHERE 
    rs.sales_rank <= 10 
    AND (tc.total_return_amt IS NULL OR tc.total_return_amt < 500)
ORDER BY 
    rs.total_sales DESC, tc.total_return_amt DESC;
