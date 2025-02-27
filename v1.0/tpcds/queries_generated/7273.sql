
WITH SalesSummary AS (
    SELECT 
        w.w_warehouse_id,
        i.i_item_id,
        SUM(ws.ws_quantity) AS total_quantity_sold,
        SUM(ws.ws_net_paid) AS total_sales,
        DATE(d.d_date) AS sales_date
    FROM 
        web_sales ws
    JOIN 
        item i ON ws.ws_item_sk = i.i_item_sk
    JOIN 
        warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year = 2023 AND 
        d.d_moy IN (6, 7) -- June and July
    GROUP BY 
        w.w_warehouse_id, i.i_item_id, DATE(d.d_date)
), 
RankedSales AS (
    SELECT 
        warehouse_id,
        item_id,
        total_quantity_sold,
        total_sales,
        sales_date,
        RANK() OVER (PARTITION BY warehouse_id ORDER BY total_sales DESC) AS sales_rank
    FROM 
        SalesSummary
)
SELECT 
    warehouse_id,
    item_id,
    total_quantity_sold,
    total_sales,
    sales_date
FROM 
    RankedSales
WHERE 
    sales_rank <= 5 -- Top 5 items by sales per warehouse
ORDER BY 
    warehouse_id, total_sales DESC;
