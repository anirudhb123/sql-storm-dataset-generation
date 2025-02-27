
WITH SalesData AS (
    SELECT 
        ws.web_site_id,
        d.d_year AS sale_year,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        SUM(ws.ws_quantity) AS total_quantity,
        AVG(ws.ws_net_profit) AS avg_profit
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN 
        web_site w ON ws.ws_web_site_sk = w.web_site_sk
    WHERE 
        d.d_year BETWEEN 2020 AND 2023
    GROUP BY 
        ws.web_site_id, d.d_year
), RankedSales AS (
    SELECT 
        web_site_id,
        sale_year,
        total_sales,
        total_quantity,
        avg_profit,
        RANK() OVER (PARTITION BY sale_year ORDER BY total_sales DESC) AS sales_rank
    FROM 
        SalesData
)
SELECT 
    r.sale_year,
    r.web_site_id,
    r.total_sales,
    r.total_quantity,
    r.avg_profit
FROM 
    RankedSales r
WHERE 
    r.sales_rank <= 5
ORDER BY 
    r.sale_year, r.total_sales DESC;
