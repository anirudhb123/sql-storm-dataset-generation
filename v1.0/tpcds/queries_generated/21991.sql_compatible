
WITH RankedSales AS (
    SELECT 
        ws.web_site_sk,
        ws.ws_order_number,
        ws.ws_quantity,
        ws.ws_net_paid,
        RANK() OVER (PARTITION BY ws.web_site_sk ORDER BY ws.ws_net_paid DESC) AS sales_rank
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk >= (SELECT MAX(d_date_sk) - 30 FROM date_dim)
),
RecentReturns AS (
    SELECT 
        wr_order_number,
        SUM(wr_return_quantity) AS total_returned,
        SUM(wr_return_amt) AS total_return_amount
    FROM 
        web_returns 
    GROUP BY 
        wr_order_number
),
SalesWithReturns AS (
    SELECT 
        rs.web_site_sk,
        rs.ws_order_number,
        rs.ws_quantity,
        COALESCE(rr.total_returned, 0) AS total_returned,
        COALESCE(rr.total_return_amount, 0) AS total_return_amount,
        rs.ws_net_paid - COALESCE(rr.total_return_amount, 0) AS net_after_returns
    FROM 
        RankedSales rs
    LEFT JOIN 
        RecentReturns rr ON rs.ws_order_number = rr.wr_order_number
)
SELECT 
    w.web_site_id,
    SUM(sw.ws_quantity) AS total_sold,
    AVG(CASE 
        WHEN sw.net_after_returns > 0 THEN sw.net_after_returns 
        ELSE NULL 
    END) AS average_net_sales,
    COUNT(DISTINCT sw.ws_order_number) AS total_unique_orders
FROM 
    SalesWithReturns sw
JOIN 
    web_site w ON sw.web_site_sk = w.web_site_sk
WHERE 
    sw.total_returned < 5
GROUP BY 
    w.web_site_id
HAVING 
    COUNT(DISTINCT sw.ws_order_number) > 10
ORDER BY 
    average_net_sales DESC
LIMIT 10;
