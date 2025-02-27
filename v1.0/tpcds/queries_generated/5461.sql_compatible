
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_net_paid) AS total_sales
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        ws.ws_sold_date_sk BETWEEN (SELECT MAX(d.d_date_sk) FROM date_dim d WHERE d.d_year = 2023) - 30 AND (SELECT MAX(d.d_date_sk) FROM date_dim d WHERE d.d_year = 2023)
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
), TotalReturns AS (
    SELECT 
        sr.sr_customer_sk,
        SUM(sr.sr_return_amt) AS total_returns
    FROM 
        store_returns sr
    WHERE 
        sr.sr_returned_date_sk BETWEEN (SELECT MAX(d.d_date_sk) FROM date_dim d WHERE d.d_year = 2023) - 30 AND (SELECT MAX(d.d_date_sk) FROM date_dim d WHERE d.d_year = 2023)
    GROUP BY 
        sr.sr_customer_sk
), SalesSummary AS (
    SELECT 
        cs.c_customer_sk,
        cs.c_first_name,
        cs.c_last_name,
        COALESCE(tr.total_returns, 0) AS total_returns,
        cs.total_sales - COALESCE(tr.total_returns, 0) AS net_sales
    FROM 
        CustomerSales cs
    LEFT JOIN 
        TotalReturns tr ON cs.c_customer_sk = tr.sr_customer_sk
)
SELECT 
    s.c_first_name,
    s.c_last_name,
    s.total_sales,
    s.total_returns,
    s.net_sales
FROM 
    SalesSummary s
ORDER BY 
    s.net_sales DESC
LIMIT 10;
