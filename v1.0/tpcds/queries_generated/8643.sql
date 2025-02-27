
WITH SalesData AS (
    SELECT 
        ws.web_site_id,
        SUM(ws.ws_sales_price * ws.ws_quantity) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        COUNT(DISTINCT ws.ws_bill_customer_sk) AS unique_customers,
        AVG(ws.ws_ext_discount_amt) AS avg_discount,
        DENSE_RANK() OVER (ORDER BY SUM(ws.ws_sales_price * ws.ws_quantity) DESC) AS sales_rank
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN 
        web_site w ON ws.ws_web_site_sk = w.web_site_sk
    WHERE 
        d.d_year = 2023
    GROUP BY 
        ws.web_site_id
), RankedSales AS (
    SELECT 
        web_site_id,
        total_sales,
        total_orders,
        unique_customers,
        avg_discount,
        sales_rank
    FROM 
        SalesData
    WHERE 
        sales_rank <= 10
)
SELECT 
    r.web_site_id,
    r.total_sales,
    r.total_orders,
    r.unique_customers,
    r.avg_discount,
    w.web_name AS website_name
FROM 
    RankedSales r
JOIN 
    web_site w ON r.web_site_id = w.web_site_id
ORDER BY 
    r.total_sales DESC;
