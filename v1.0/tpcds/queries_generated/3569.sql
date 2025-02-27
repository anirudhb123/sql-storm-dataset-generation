
WITH ranked_sales AS (
    SELECT 
        ws.web_site_sk,
        ws.web_name,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        RANK() OVER (PARTITION BY ws.web_site_sk ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS sales_rank
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2023
    GROUP BY 
        ws.web_site_sk, ws.web_name
),
high_volume_sales AS (
    SELECT 
        s.s_store_name,
        SUM(ss.ss_quantity) AS total_quantity_sold,
        SUM(ss.ss_net_profit) AS total_net_profit,
        ROUND(SUM(ss.ss_net_profit) / NULLIF(SUM(ss.ss_quantity), 0), 2) AS avg_profit_per_item
    FROM 
        store_sales ss
    JOIN 
        store s ON ss.ss_store_sk = s.s_store_sk
    GROUP BY 
        s.s_store_name
    HAVING 
        total_quantity_sold > 1000
)
SELECT 
    wh.w_warehouse_name,
    COUNT(DISTINCT ca.ca_address_sk) AS total_addresses,
    COALESCE(SUM(hvs.total_quantity_sold), 0) AS total_quantity_sold,
    COALESCE(SUM(hvs.total_net_profit), 0) AS total_net_profit
FROM 
    warehouse wh
LEFT JOIN 
    customer_address ca ON wh.w_warehouse_sk = ca.ca_address_sk
LEFT JOIN 
    high_volume_sales hvs ON wh.w_warehouse_sk = hvs.total_quantity_sold
WHERE 
    wh.w_country = 'USA'
GROUP BY 
    wh.w_warehouse_name
HAVING 
    COUNT(DISTINCT ca.ca_address_sk) > 0
ORDER BY 
    total_net_profit DESC;
