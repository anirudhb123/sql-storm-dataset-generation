
WITH RankedSales AS (
    SELECT 
        ws.web_site_sk,
        COUNT(DISTINCT ws_order_number) AS total_orders,
        SUM(ws_net_paid) AS total_sales,
        AVG(ws_net_paid) AS avg_order_value,
        SUM(ws_ext_discount_amt) AS total_discounted,
        ROW_NUMBER() OVER (ORDER BY SUM(ws_net_paid) DESC) AS rank
    FROM 
        web_sales ws 
    JOIN 
        web_site w ON ws.ws_web_site_sk = w.web_site_sk
    WHERE 
        ws.ws_sold_date_sk BETWEEN (SELECT d_date_sk FROM date_dim WHERE d_date = '2023-01-01') AND 
                                   (SELECT d_date_sk FROM date_dim WHERE d_date = '2023-12-31')
    GROUP BY 
        ws.web_site_sk
    HAVING 
        COUNT(DISTINCT ws_order_number) > 0
),
TopWebsites AS (
    SELECT 
        rank, 
        web_site_id, 
        total_orders,
        total_sales,
        avg_order_value,
        total_discounted 
    FROM 
        RankedSales rs
    JOIN 
        web_site ws ON rs.web_site_sk = ws.web_site_sk
)
SELECT 
    tw.rank, 
    tw.web_site_id, 
    tw.total_orders, 
    tw.total_sales, 
    tw.avg_order_value, 
    tw.total_discounted
FROM 
    TopWebsites tw
WHERE 
    tw.rank <= 10
ORDER BY 
    tw.total_sales DESC;
