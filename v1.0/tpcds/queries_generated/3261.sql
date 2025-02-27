
WITH RankedSales AS (
    SELECT 
        ws.web_site_id,
        ws_sold_date_sk,
        SUM(ws_quantity) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws.web_site_id ORDER BY SUM(ws_quantity) DESC) AS sales_rank
    FROM 
        web_sales ws
    JOIN 
        web_site w ON ws.ws_web_site_sk = w.web_site_sk
    GROUP BY 
        ws.web_site_id, ws_sold_date_sk
),
CustomerReturns AS (
    SELECT 
        wr.returning_customer_sk,
        SUM(wr.return_quantity) AS total_returns,
        COUNT(DISTINCT wr_order_number) AS return_count,
        ROW_NUMBER() OVER (PARTITION BY wr.returning_customer_sk ORDER BY SUM(wr.return_quantity) DESC) AS return_rank
    FROM 
        web_returns wr
    GROUP BY 
        wr.returning_customer_sk
),
SalesAndReturns AS (
    SELECT 
        rs.web_site_id, 
        rs.ws_sold_date_sk,
        rs.total_sales,
        COALESCE(cr.total_returns, 0) AS total_returns,
        cr.return_count,
        rs.total_sales - COALESCE(cr.total_returns, 0) AS net_sales
    FROM 
        RankedSales rs
    LEFT JOIN 
        CustomerReturns cr ON rs.web_site_id = cr.returning_customer_sk  -- Assuming a relationship for demonstration
)
SELECT 
    w.web_name,
    date_dim.d_date AS sale_date,
    SUM(sar.net_sales) AS net_sales,
    SUM(sar.total_returns) AS total_returns,
    ROUND(SUM(sar.net_sales) / NULLIF(SUM(sar.total_returns), 0), 2) AS sales_to_returns_ratio,
    COUNT(DISTINCT sar.web_site_id) AS unique_websites
FROM 
    SalesAndReturns sar
JOIN 
    date_dim ON date_dim.d_date_sk = sar.ws_sold_date_sk
JOIN 
    web_site w ON sar.web_site_id = w.web_site_id
WHERE 
    date_dim.d_year = 2023
GROUP BY 
    w.web_name, date_dim.d_date
HAVING 
    SUM(sar.net_sales) > 1000
ORDER BY 
    net_sales DESC;
