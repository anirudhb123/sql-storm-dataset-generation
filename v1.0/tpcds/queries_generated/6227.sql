
WITH SalesData AS (
    SELECT 
        ws.web_site_id, 
        d.d_year, 
        i.i_category, 
        SUM(ws.ws_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        AVG(ws.ws_sales_price) AS avg_sales_price
    FROM 
        web_sales ws
    JOIN 
        item i ON ws.ws_item_sk = i.i_item_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year BETWEEN 2021 AND 2023
        AND ws.ws_sales_price > 0
    GROUP BY 
        ws.web_site_id, 
        d.d_year, 
        i.i_category
    HAVING 
        SUM(ws.ws_sales_price) > 100000
), CategoryPerformance AS (
    SELECT 
        web_site_id, 
        d_year,
        i_category,
        total_sales,
        total_orders,
        avg_sales_price,
        RANK() OVER (PARTITION BY d_year ORDER BY total_sales DESC) AS sales_rank
    FROM 
        SalesData
)
SELECT 
    web_site_id, 
    d_year, 
    i_category, 
    total_sales, 
    total_orders, 
    avg_sales_price, 
    sales_rank
FROM 
    CategoryPerformance
WHERE 
    sales_rank <= 10
ORDER BY 
    d_year, 
    sales_rank;
