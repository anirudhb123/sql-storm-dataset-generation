
WITH RankedSales AS (
    SELECT 
        ws.web_site_sk,
        ws_sales_price,
        ws_quantity,
        RANK() OVER (PARTITION BY ws.web_site_sk ORDER BY ws_sales_price DESC) as price_rank,
        RANK() OVER (PARTITION BY ws.web_site_sk ORDER BY ws_quantity DESC) as quantity_rank
    FROM 
        web_sales ws
    JOIN 
        web_site w ON ws.ws_web_site_sk = w.web_site_sk
    WHERE 
        ws_ship_date_sk BETWEEN 2458855 AND 2459110
),
TopSales AS (
    SELECT 
        web_site_sk,
        SUM(ws_sales_price * ws_quantity) AS total_sales
    FROM 
        RankedSales
    WHERE 
        price_rank <= 10 OR quantity_rank <= 10
    GROUP BY 
        web_site_sk
)
SELECT 
    ws.web_site_id,
    ws.web_name,
    COALESCE(ts.total_sales, 0) AS calculated_sales
FROM 
    web_site ws
LEFT JOIN 
    TopSales ts ON ws.web_site_sk = ts.web_site_sk
ORDER BY 
    calculated_sales DESC
LIMIT 20;
