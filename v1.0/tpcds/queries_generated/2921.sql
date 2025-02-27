
WITH RankedWebSales AS (
    SELECT 
        ws.web_site_sk,
        ws_sold_date_sk,
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_paid_inc_tax) AS total_revenue,
        ROW_NUMBER() OVER (PARTITION BY ws.web_site_sk ORDER BY SUM(ws_net_paid_inc_tax) DESC) AS rank
    FROM 
        web_sales ws
    JOIN 
        item i ON ws.ws_item_sk = i.i_item_sk
    WHERE 
        i.i_rec_start_date <= (SELECT MAX(d_date) FROM date_dim WHERE d_current_year = 'Y')
        AND i.i_rec_end_date >= (SELECT MIN(d_date) FROM date_dim WHERE d_current_year = 'Y')
    GROUP BY 
        ws.web_site_sk, ws_sold_date_sk, ws_item_sk
)
SELECT 
    w.web_site_id,
    COALESCE(rws.total_quantity, 0) AS total_quantity,
    COALESCE(rws.total_revenue, 0) AS total_revenue
FROM 
    web_site w
LEFT JOIN 
    RankedWebSales rws ON w.web_site_sk = rws.web_site_sk
WHERE 
    (total_revenue > 10000 OR EXISTS (
        SELECT 1
        FROM store_sales ss
        WHERE ss.ss_sold_date_sk = rws.ws_sold_date_sk
        AND ss.ss_item_sk = rws.ws_item_sk
        AND ss.ss_quantity > 50
    ))
ORDER BY 
    w.web_site_id;

-- Additional calculations and summary metrics
SELECT 
    COUNT(DISTINCT w.web_site_sk) AS total_websites,
    AVG(rws.total_revenue) AS avg_revenue_per_website,
    MAX(rws.total_quantity) AS max_quantity_sold
FROM 
    RankedWebSales rws
JOIN 
    web_site w ON rws.web_site_sk = w.web_site_sk;
