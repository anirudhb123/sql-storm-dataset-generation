
WITH SalesData AS (
    SELECT 
        ws.web_site_id,
        SUM(ws.ws_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS total_orders
    FROM 
        web_sales ws
    JOIN 
        web_site w ON ws.ws_web_site_sk = w.web_site_sk
    WHERE 
        ws.ws_sold_date_sk BETWEEN 2451545 AND 2451545 + 30 -- Example date range
    GROUP BY 
        ws.web_site_id
)
SELECT 
    sd.web_site_id,
    sd.total_sales,
    sd.total_orders,
    (sd.total_sales / NULLIF(sd.total_orders, 0)) AS avg_order_value
FROM 
    SalesData sd
ORDER BY 
    total_sales DESC;
