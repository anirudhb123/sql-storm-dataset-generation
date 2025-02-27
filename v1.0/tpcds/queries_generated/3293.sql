
WITH RankedSales AS (
    SELECT 
        ws.web_site_id,
        ws.web_name,
        ws.ws_date_sk,
        SUM(ws.ws_sales_price) AS total_sales,
        RANK() OVER (PARTITION BY ws.web_site_id ORDER BY SUM(ws.ws_sales_price) DESC) AS sales_rank
    FROM 
        web_sales ws
    JOIN 
        web_site w ON ws.ws_web_site_sk = w.web_site_sk
    GROUP BY 
        ws.web_site_id, ws.web_name, ws.ws_date_sk
),
CustomerReturns AS (
    SELECT 
        wr_returning_customer_sk,
        COUNT(DISTINCT wr_order_number) AS return_count,
        SUM(wr_return_amt) AS total_return_amt
    FROM 
        web_returns
    GROUP BY 
        wr_returning_customer_sk
),
SalesAndReturns AS (
    SELECT 
        cs_bill_customer_sk AS customer_sk,
        SUM(cs_ext_sales_price) AS total_sales,
        COALESCE(cr.return_count, 0) AS total_returns,
        COALESCE(cr.total_return_amt, 0) AS return_amount
    FROM 
        catalog_sales cs
    LEFT JOIN 
        CustomerReturns cr ON cs_bill_customer_sk = cr.wr_returning_customer_sk
    GROUP BY 
        cs_bill_customer_sk
)
SELECT 
    c.c_customer_id,
    COALESCE(s.total_sales, 0) AS total_sales,
    COALESCE(s.total_returns, 0) AS total_returns,
    COALESCE(s.return_amount, 0) AS return_amount,
    RANK() OVER (ORDER BY COALESCE(s.total_sales, 0) DESC) AS sales_rank
FROM 
    customer c
LEFT JOIN 
    SalesAndReturns s ON c.c_customer_sk = s.customer_sk
WHERE 
    (s.total_sales > 1000 OR s.return_amount > 500)
ORDER BY 
    sales_rank
LIMIT 100;
