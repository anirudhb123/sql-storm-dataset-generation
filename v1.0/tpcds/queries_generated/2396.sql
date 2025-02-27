
WITH RankedSales AS (
    SELECT 
        ws.web_site_sk,
        ws.ws_order_number,
        ws.ws_item_sk,
        ws.ws_quantity,
        ws.ws_net_paid,
        RANK() OVER (PARTITION BY ws.web_site_sk ORDER BY ws.ws_net_paid DESC) AS rn
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk >= (SELECT MAX(d.d_date_sk) FROM date_dim d WHERE d.d_year = 2023)
)

SELECT 
    w.warehouse_id,
    w.warehouse_name,
    SUM(COALESCE(ws.ws_quantity, 0)) AS total_quantity_sold,
    SUM(COALESCE(ws.ws_net_paid, 0)) AS total_net_paid,
    AVG(COALESCE(ws.ws_net_paid, 0)) AS avg_net_paid
FROM 
    warehouse w
LEFT JOIN 
    web_sales ws ON w.warehouse_sk = ws.ws_warehouse_sk
LEFT JOIN 
    RankedSales rs ON ws.ws_order_number = rs.ws_order_number
WHERE 
    w.warehouse_sq_ft > 1000
    AND (ws.ws_quantity < 10 OR ws.ws_net_paid IS NULL)
GROUP BY 
    w.warehouse_id, w.warehouse_name
HAVING 
    total_quantity_sold > 100
    AND AVG(ws.ws_net_paid) BETWEEN 50 AND 150
ORDER BY 
    total_net_paid DESC
FETCH FIRST 10 ROWS ONLY;
