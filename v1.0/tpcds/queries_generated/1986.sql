
WITH RankedSales AS (
    SELECT 
        ws.web_site_sk,
        SUM(ws.ws_net_paid) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws.web_site_sk ORDER BY SUM(ws.ws_net_paid) DESC) AS sales_rank
    FROM 
        web_sales ws
    JOIN 
        web_site w ON ws.ws_web_site_sk = w.web_site_sk
    WHERE 
        ws.ws_sold_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023) 
                                AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        ws.web_site_sk
),
TopWebsites AS (
    SELECT 
        web_site_id,
        total_sales
    FROM 
        RankedSales rs
    JOIN 
        web_site w ON rs.web_site_sk = w.web_site_sk
    WHERE 
        sales_rank <= 5
),
CustomerReturns AS (
    SELECT 
        wr_returning_customer_sk,
        SUM(wr_return_amt) AS total_return_amt
    FROM 
        web_returns
    GROUP BY 
        wr_returning_customer_sk
),
SalesWithReturns AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_net_paid,
        COALESCE(cr.total_return_amt, 0) AS return_amt,
        (ws.ws_net_paid - COALESCE(cr.total_return_amt, 0)) AS net_sales
    FROM 
        web_sales ws
    LEFT JOIN 
        CustomerReturns cr ON ws.ws_bill_customer_sk = cr.wr_returning_customer_sk
)
SELECT 
    t.web_site_id,
    t.total_sales,
    SUM(swr.net_sales) AS adjusted_net_sales
FROM 
    TopWebsites t
LEFT JOIN 
    SalesWithReturns swr ON t.total_sales > 0 
GROUP BY 
    t.web_site_id, t.total_sales
ORDER BY 
    adjusted_net_sales DESC
LIMIT 10;
