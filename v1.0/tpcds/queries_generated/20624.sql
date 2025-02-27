
WITH RankedSales AS (
    SELECT 
        ws.web_site_id,
        ws.ws_order_number,
        ws.ws_quantity,
        ws.ws_sales_price,
        ROW_NUMBER() OVER (PARTITION BY ws.web_site_id ORDER BY ws.ws_sales_price DESC) AS rank_price,
        ROW_NUMBER() OVER (PARTITION BY ws.web_site_id ORDER BY ws.ws_quantity DESC) AS rank_quantity,
        SUM(ws.ws_sales_price) OVER (PARTITION BY ws.web_site_sk) AS total_sales
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2023
),
FilteredSales AS (
    SELECT 
        rs.web_site_id,
        rs.ws_order_number,
        rs.ws_quantity,
        rs.ws_sales_price,
        rs.total_sales,
        (CASE WHEN rs.ws_sales_price IS NULL THEN 'No Price' 
              WHEN rs.ws_sales_price > 100 THEN 'Expensive' 
              ELSE 'Affordable' END) AS price_category
    FROM 
        RankedSales rs
    WHERE 
        (rs.rank_price <= 5 OR rs.rank_quantity <= 5)
)
SELECT 
    fs.web_site_id,
    COUNT(DISTINCT fs.ws_order_number) AS num_orders,
    MAX(fs.ws_quantity) AS max_quantity,
    SUM(fs.ws_sales_price) AS total_revenue,
    SUM(CASE WHEN fs.price_category = 'Expensive' THEN fs.ws_sales_price ELSE 0 END) AS total_expensive_revenue,
    STRING_AGG(DISTINCT fs.price_category) AS unique_price_categories
FROM 
    FilteredSales fs
GROUP BY 
    fs.web_site_id
HAVING 
    total_revenue > 5000
ORDER BY 
    total_revenue DESC
LIMIT 10;
