
WITH RankedSales AS (
    SELECT 
        ws.web_site_sk,
        ws.web_site_id,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        DENSE_RANK() OVER (PARTITION BY ws.web_site_sk ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS sales_rank
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2023
    GROUP BY 
        ws.web_site_sk, ws.web_site_id
),
CustomerReturns AS (
    SELECT 
        wr_refunded_customer_sk,
        SUM(wr_return_amt) AS total_return
    FROM 
        web_returns
    GROUP BY 
        wr_refunded_customer_sk
),
SalesWithReturns AS (
    SELECT 
        ws.web_site_sk,
        rs.total_sales,
        COALESCE(cr.total_return, 0) AS total_return,
        (rs.total_sales - COALESCE(cr.total_return, 0)) AS net_sales
    FROM 
        RankedSales rs
    LEFT JOIN 
        CustomerReturns cr ON rs.web_site_sk = cr.wr_refunded_customer_sk
)
SELECT 
    swr.web_site_sk,
    swr.total_sales,
    swr.total_return,
    swr.net_sales,
    CASE 
        WHEN swr.net_sales < 0 THEN 'Negative Sales'
        WHEN swr.net_sales > 0 AND swr.total_sales > 100000 THEN 'High Performer'
        ELSE 'Average Performer'
    END AS performance_category
FROM 
    SalesWithReturns swr
WHERE 
    swr.sales_rank = 1
ORDER BY 
    swr.net_sales DESC;

