
WITH RankedSales AS (
    SELECT 
        ws.web_site_id, 
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_paid) AS total_revenue,
        ROW_NUMBER() OVER (PARTITION BY ws.web_site_id ORDER BY SUM(ws.ws_net_paid) DESC) AS rank
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2023 AND dd.d_month_seq BETWEEN 1 AND 12
    GROUP BY 
        ws.web_site_id
),

TopSites AS (
    SELECT 
        web_site_id, 
        total_quantity,
        total_revenue
    FROM 
        RankedSales
    WHERE 
        rank <= 5
)

SELECT 
    t.web_site_id,
    SUM(s.ws_quantity) AS total_quantity_sold,
    AVG(s.ws_net_paid_inc_tax) AS average_revenue_per_transaction,
    s.ws_ship_date_sk,
    COALESCE(SUM(rsr.return_quantity), 0) AS total_returned_quantity
FROM 
    TopSites t
JOIN 
    web_sales s ON t.web_site_id = s.ws_web_site_sk
LEFT JOIN 
    (SELECT 
        wr_item_sk, 
        SUM(wr_return_quantity) AS return_quantity 
     FROM 
        web_returns 
     GROUP BY 
        wr_item_sk) rsr ON s.ws_item_sk = rsr.wr_item_sk
GROUP BY 
    t.web_site_id, 
    s.ws_ship_date_sk
ORDER BY 
    total_quantity_sold DESC;
