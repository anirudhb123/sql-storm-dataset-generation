
WITH SalesData AS (
    SELECT 
        ws.web_site_id,
        d.d_year,
        d.d_month_seq,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_paid) AS total_sales,
        AVG(ws.ws_net_profit) AS avg_profit
    FROM 
        web_sales ws 
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN 
        web_site w ON ws.ws_web_site_sk = w.web_site_sk
    GROUP BY 
        ws.web_site_id, d.d_year, d.d_month_seq
), RankedSales AS (
    SELECT 
        *,
        RANK() OVER (PARTITION BY d_year ORDER BY total_sales DESC) AS sales_rank
    FROM 
        SalesData
), TopWebSites AS (
    SELECT 
        web_site_id, 
        d_year, 
        d_month_seq, 
        total_quantity, 
        total_sales, 
        avg_profit
    FROM 
        RankedSales 
    WHERE 
        sales_rank <= 5
)
SELECT 
    t.web_site_id,
    t.d_year,
    t.d_month_seq,
    t.total_quantity,
    t.total_sales,
    t.avg_profit,
    w.w_warehouse_name,
    COUNT(DISTINCT sd.ss_item_sk) AS unique_items_sold
FROM 
    TopWebSites t
JOIN 
    store_sales sd ON t.total_sales = sd.ss_sales_price
JOIN 
    warehouse w ON sd.ss_store_sk = w.w_warehouse_sk
GROUP BY 
    t.web_site_id, t.d_year, t.d_month_seq, t.total_quantity, t.total_sales, t.avg_profit, w.w_warehouse_name
ORDER BY 
    t.d_year, t.total_sales DESC;
