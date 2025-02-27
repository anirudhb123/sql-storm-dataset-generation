
WITH SalesData AS (
    SELECT 
        ws.web_site_id,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        COUNT(DISTINCT ws.ws_bill_customer_sk) AS unique_customers
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
    sd.unique_customers,
    (sd.total_sales / NULLIF(sd.total_orders, 0)) AS average_order_value
FROM 
    SalesData sd
ORDER BY 
    sd.total_sales DESC;
