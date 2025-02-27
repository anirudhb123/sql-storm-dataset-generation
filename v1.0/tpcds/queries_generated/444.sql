
WITH RankedSales AS (
    SELECT 
        ws.web_site_sk,
        ws.ws_order_number,
        ws.ws_quantity,
        ws.ws_sales_price,
        ROW_NUMBER() OVER (PARTITION BY ws.web_site_sk ORDER BY ws.ws_sales_price DESC) AS rank
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk BETWEEN 1000 AND 2000
),
CustomerReturns AS (
    SELECT 
        wr_returning_customer_sk,
        SUM(wr_return_quantity) AS total_returned
    FROM 
        web_returns
    GROUP BY 
        wr_returning_customer_sk
),
SalesWithReturns AS (
    SELECT 
        r.rank,
        r.web_site_sk,
        r.ws_order_number,
        r.ws_quantity,
        r.ws_sales_price,
        COALESCE(cr.total_returned, 0) AS total_returned
    FROM 
        RankedSales r
    LEFT JOIN 
        CustomerReturns cr ON r.ws_order_number = cr.wr_returning_customer_sk
)
SELECT 
    s.web_site_sk,
    SUM(s.ws_sales_price * s.ws_quantity) AS total_sales,
    SUM(s.total_returned) AS total_returns,
    (SUM(s.ws_sales_price * s.ws_quantity) - SUM(s.total_returned)) AS net_sales,
    AVG(s.ws_sales_price) AS avg_sales_price,
    COUNT(s.ws_order_number) AS order_count
FROM 
    SalesWithReturns s
WHERE 
    s.rank <= 5
GROUP BY 
    s.web_site_sk
HAVING 
    total_sales > 1000
ORDER BY 
    net_sales DESC;
