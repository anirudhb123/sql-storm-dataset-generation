
WITH RankedSales AS (
    SELECT 
        ws.web_site_sk, 
        ws_sold_date_sk, 
        SUM(ws_net_paid_inc_tax) AS total_sales,
        DENSE_RANK() OVER (PARTITION BY ws.web_site_sk ORDER BY SUM(ws_net_paid_inc_tax) DESC) AS sales_rank
    FROM 
        web_sales ws
    JOIN 
        web_site w ON ws.ws_web_site_sk = w.web_site_sk
    GROUP BY 
        ws.web_site_sk, ws_sold_date_sk
),
TopSales AS (
    SELECT 
        web_site_sk, 
        ws_sold_date_sk, 
        total_sales
    FROM 
        RankedSales 
    WHERE 
        sales_rank <= 5
),
CustomerReturns AS (
    SELECT 
        sr_customer_sk, 
        SUM(sr_return_amt_inc_tax) AS total_returns
    FROM 
        store_returns
    WHERE 
        sr_returned_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        sr_customer_sk
)
SELECT 
    c.c_customer_id,
    COALESCE(SUM(ts.total_sales), 0) AS total_sales,
    COALESCE(cr.total_returns, 0) AS total_returns,
    COALESCE(SUM(ts.total_sales), 0) - COALESCE(cr.total_returns, 0) AS net_revenue
FROM 
    customer c
LEFT JOIN 
    TopSales ts ON c.c_customer_sk = ts.ws_sold_date_sk
LEFT JOIN 
    CustomerReturns cr ON c.c_customer_sk = cr.sr_customer_sk
GROUP BY 
    c.c_customer_id, cr.total_returns
HAVING 
    COALESCE(SUM(ts.total_sales), 0) - COALESCE(cr.total_returns, 0) > 1000
ORDER BY 
    net_revenue DESC;
