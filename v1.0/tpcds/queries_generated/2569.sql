
WITH RankedSales AS (
    SELECT 
        ws.web_site_sk,
        ws.ws_order_number,
        ws.ws_sales_price,
        ws.ws_sold_date_sk,
        ROW_NUMBER() OVER (PARTITION BY ws.web_site_sk ORDER BY ws.ws_sales_price DESC) AS rn
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk BETWEEN 20200101 AND 20201231
),
MaxSales AS (
    SELECT 
        web_site_sk,
        MAX(ws_sales_price) AS max_sales_price
    FROM 
        RankedSales
    WHERE 
        rn <= 10
    GROUP BY 
        web_site_sk
)
SELECT 
    w.w_warehouse_name,
    COALESCE(w.w_country, 'Unknown') AS country,
    COUNT(DISTINCT ws.ws_order_number) AS total_orders,
    SUM(COALESCE(ws.ws_sales_price, 0)) AS total_sales,
    AVG(m.max_sales_price) AS avg_top_sale
FROM 
    warehouse w
LEFT JOIN 
    web_sales ws ON w.w_warehouse_sk = ws.ws_warehouse_sk
LEFT JOIN 
    MaxSales m ON w.w_warehouse_sk = m.web_site_sk
WHERE 
    w.w_warehouse_name IS NOT NULL
    AND w.w_warehouse_sq_ft IS NOT NULL
GROUP BY 
    w.w_warehouse_name, w.w_country
HAVING 
    AVG(m.max_sales_price) > 100
ORDER BY 
    total_sales DESC, avg_top_sale DESC;
