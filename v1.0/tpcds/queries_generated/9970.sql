
WITH RankedSales AS (
    SELECT 
        w.warehouse_id,
        i.i_item_id,
        SUM(ws.ws_quantity) AS total_quantity_sold,
        SUM(ws.ws_sales_price) AS total_revenue,
        DENSE_RANK() OVER (PARTITION BY w.warehouse_id ORDER BY SUM(ws.ws_sales_price) DESC) AS revenue_rank
    FROM 
        web_sales ws
    JOIN 
        warehouse w ON ws.ws_warehouse_sk = w.warehouse_sk
    JOIN 
        item i ON ws.ws_item_sk = i.i_item_sk
    WHERE 
        ws.ws_sold_date_sk BETWEEN 1 AND 365
    GROUP BY 
        w.warehouse_id, i.i_item_id
),
TopSellingItems AS (
    SELECT 
        warehouse_id,
        i_item_id,
        total_quantity_sold,
        total_revenue
    FROM 
        RankedSales
    WHERE 
        revenue_rank <= 5
)
SELECT 
    tsi.warehouse_id,
    COUNT(tsi.i_item_id) AS top_items_count,
    SUM(tsi.total_quantity_sold) AS total_quantity_sold,
    SUM(tsi.total_revenue) AS total_revenue,
    AVG(tsi.total_revenue / NULLIF(tsi.total_quantity_sold, 0)) AS average_sale_price
FROM 
    TopSellingItems tsi
GROUP BY 
    tsi.warehouse_id
ORDER BY 
    total_revenue DESC;
