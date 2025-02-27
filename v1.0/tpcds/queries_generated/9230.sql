
WITH RankedSales AS (
    SELECT 
        ws.web_site_sk,
        ws.ws_order_number,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_paid) AS total_net_paid,
        ROW_NUMBER() OVER (PARTITION BY ws.web_site_sk ORDER BY SUM(ws.ws_net_paid) DESC) AS rank
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2023 AND dd.d_month_seq IN (5, 6)
    GROUP BY 
        ws.web_site_sk, ws.ws_order_number
),
TopSales AS (
    SELECT 
        rs.web_site_sk,
        rs.total_quantity,
        rs.total_net_paid
    FROM 
        RankedSales rs
    WHERE 
        rs.rank <= 5
)
SELECT 
    w.warehouse_id,
    w.warehouse_name,
    COALESCE(SUM(ts.total_quantity), 0) AS total_quantity,
    COALESCE(SUM(ts.total_net_paid), 0) AS total_net_paid
FROM 
    warehouse w
LEFT JOIN 
    TopSales ts ON w.warehouse_sk = ts.web_site_sk
GROUP BY 
    w.warehouse_id, w.warehouse_name
ORDER BY 
    total_net_paid DESC;
