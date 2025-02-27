
WITH RankedSales AS (
    SELECT 
        ws.web_site_sk,
        ws.web_site_id,
        SUM(ws.ws_net_paid) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        ROW_NUMBER() OVER (PARTITION BY ws.web_site_sk ORDER BY SUM(ws.ws_net_paid) DESC) AS rank
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2023 AND 
        dd.d_quarter_seq IN (1, 2) 
    GROUP BY 
        ws.web_site_sk, ws.web_site_id
), HighestSales AS (
    SELECT 
        web_site_sk, 
        web_site_id, 
        total_sales, 
        total_orders
    FROM 
        RankedSales
    WHERE 
        rank = 1
)
SELECT 
    h.web_site_id,
    h.total_sales,
    h.total_orders,
    c.cc_name AS call_center_name,
    SUM(ss.ss_net_profit) AS total_store_profit
FROM 
    HighestSales h
LEFT JOIN 
    call_center c ON h.web_site_sk = c.cc_call_center_sk
LEFT JOIN 
    store_sales ss ON ss.ss_customer_sk IN (SELECT DISTINCT ws_ship_customer_sk FROM web_sales WHERE ws_web_site_sk = h.web_site_sk)
GROUP BY 
    h.web_site_id, h.total_sales, h.total_orders, c.cc_name
ORDER BY 
    total_sales DESC;
