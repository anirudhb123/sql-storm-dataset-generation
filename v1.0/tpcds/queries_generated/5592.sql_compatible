
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM 
        customer AS c
    JOIN 
        web_sales AS ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk
),
TopCustomers AS (
    SELECT 
        cs.c_customer_sk,
        cs.total_sales,
        cs.order_count,
        ROW_NUMBER() OVER (ORDER BY cs.total_sales DESC) AS sales_rank
    FROM 
        CustomerSales AS cs
),
RecentReturns AS (
    SELECT 
        sr.sr_customer_sk,
        SUM(sr.sr_return_amt_inc_tax) AS total_returned,
        COUNT(DISTINCT sr.sr_ticket_number) AS return_count
    FROM 
        store_returns AS sr
    WHERE 
        sr.sr_returned_date_sk >= (SELECT MAX(d_date_sk) - 30 FROM date_dim)
    GROUP BY 
        sr.sr_customer_sk
),
ReturnImpact AS (
    SELECT 
        tc.c_customer_sk,
        tc.total_sales,
        tc.order_count,
        COALESCE(rr.total_returned, 0) AS total_returned,
        COALESCE(rr.return_count, 0) AS return_count,
        (tc.total_sales - COALESCE(rr.total_returned, 0)) AS net_sales
    FROM 
        TopCustomers AS tc
    LEFT JOIN 
        RecentReturns AS rr ON tc.c_customer_sk = rr.sr_customer_sk
)
SELECT 
    r.c_customer_sk,
    r.total_sales,
    r.order_count,
    r.total_returned,
    r.return_count,
    r.net_sales,
    CASE 
        WHEN r.net_sales > 1000 THEN 'VIP'
        WHEN r.net_sales BETWEEN 500 AND 1000 THEN 'Regular'
        ELSE 'Low Value'
    END AS customer_status
FROM 
    ReturnImpact AS r
WHERE 
    r.sales_rank <= 100
ORDER BY 
    r.net_sales DESC;
