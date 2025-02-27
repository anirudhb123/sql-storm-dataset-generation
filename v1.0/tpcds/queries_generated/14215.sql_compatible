
WITH SalesData AS (
    SELECT 
        ws.web_site_id,
        SUM(ws.ws_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        AVG(ws.ws_net_paid) AS avg_net_paid
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2023
    GROUP BY 
        ws.web_site_id
)
SELECT 
    sd.web_site_id,
    sd.total_sales,
    sd.total_orders,
    sd.avg_net_paid,
    ca.ca_city,
    ca.ca_state
FROM 
    SalesData sd
JOIN 
    customer_address ca ON ca.ca_address_sk = sd.web_site_id
ORDER BY 
    sd.total_sales DESC
LIMIT 10;
