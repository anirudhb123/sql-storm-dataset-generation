
WITH sales_data AS (
    SELECT 
        ws.web_site_id,
        coalesce(ws.ws_net_profit, 0) AS net_profit,
        coalesce(cs.cs_net_profit, 0) AS catalog_net_profit,
        coalesce(ss.ss_net_profit, 0) AS store_net_profit,
        COALESCE(ws.ws_net_profit, 0) + COALESCE(cs.cs_net_profit, 0) + COALESCE(ss.ss_net_profit, 0) AS total_profit,
        dd.d_year,
        dd.d_month_seq,
        COUNT(DISTINCT ws.ws_order_number) AS web_sales_count,
        COUNT(DISTINCT cs.cs_order_number) AS catalog_sales_count,
        COUNT(DISTINCT ss.ss_ticket_number) AS store_sales_count
    FROM 
        web_sales ws
    FULL OUTER JOIN catalog_sales cs ON ws.ws_item_sk = cs.cs_item_sk AND ws.ws_sold_date_sk = cs.cs_sold_date_sk
    FULL OUTER JOIN store_sales ss ON ws.ws_item_sk = ss.ss_item_sk AND ws.ws_sold_date_sk = ss.ss_sold_date_sk
    JOIN date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk OR cs.cs_sold_date_sk = dd.d_date_sk OR ss.ss_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year BETWEEN 2019 AND 2023 
    GROUP BY 
        ws.web_site_id, dd.d_year, dd.d_month_seq
)
SELECT 
    web_site_id,
    SUM(net_profit) AS total_web_net_profit,
    SUM(catalog_net_profit) AS total_catalog_net_profit,
    SUM(store_net_profit) AS total_store_net_profit,
    SUM(total_profit) AS total_combined_net_profit,
    AVG(web_sales_count) AS avg_web_sales,
    AVG(catalog_sales_count) AS avg_catalog_sales,
    AVG(store_sales_count) AS avg_store_sales
FROM 
    sales_data
GROUP BY 
    web_site_id
ORDER BY 
    total_combined_net_profit DESC
LIMIT 10;
