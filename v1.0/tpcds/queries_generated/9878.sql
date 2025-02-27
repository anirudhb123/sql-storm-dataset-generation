
WITH RankedSales AS (
    SELECT 
        ws.web_site_id,
        DATE(d.d_date) AS sale_date,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        SUM(ws.ws_net_profit) AS total_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws.web_site_id ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS sales_rank
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year = 2023
    GROUP BY 
        ws.web_site_id, d.d_date
),
TopSales AS (
    SELECT 
        web_site_id,
        sale_date,
        total_quantity,
        total_sales,
        total_net_profit
    FROM 
        RankedSales
    WHERE 
        sales_rank <= 10
),
AverageSales AS (
    SELECT 
        web_site_id,
        AVG(total_sales) AS avg_sales,
        AVG(total_net_profit) AS avg_net_profit
    FROM 
        TopSales
    GROUP BY 
        web_site_id
)
SELECT 
    ws.web_site_id,
    ws.web_name,
    avg.avg_sales,
    avg.avg_net_profit
FROM 
    web_site ws
JOIN 
    AverageSales avg ON ws.web_site_id = avg.web_site_id
ORDER BY 
    avg.avg_sales DESC;
