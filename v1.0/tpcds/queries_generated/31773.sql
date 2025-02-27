
WITH RECURSIVE SalesCTE AS (
    SELECT 
        ws.web_site_sk,
        ws.web_name,
        SUM(ws.ws_net_profit) AS total_profit,
        ROW_NUMBER() OVER (PARTITION BY ws.web_site_sk ORDER BY SUM(ws.ws_net_profit) DESC) AS rank
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2023
    GROUP BY 
        ws.web_site_sk, ws.web_name
    HAVING 
        SUM(ws.ws_net_profit) > 10000
    UNION ALL
    SELECT 
        ws.web_site_sk,
        ws.web_name,
        SUM(ws.ws_net_profit) + cte.total_profit,
        ROW_NUMBER() OVER (PARTITION BY ws.web_site_sk ORDER BY SUM(ws.ws_net_profit) DESC)
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    JOIN 
        SalesCTE cte ON ws.web_site_sk = cte.web_site_sk
    WHERE 
        dd.d_year < 2023
    GROUP BY 
        ws.web_site_sk, ws.web_name, cte.total_profit
), 
RankedSales AS (
    SELECT 
        *,
        RANK() OVER (ORDER BY total_profit DESC) AS overall_rank
    FROM 
        SalesCTE
)
SELECT 
    r.web_name,
    r.total_profit,
    COALESCE(w.w_warehouse_name, 'No Warehouse') AS warehouse_info,
    CASE 
        WHEN r.total_profit > 50000 THEN 'High Performer'
        WHEN r.total_profit BETWEEN 20000 AND 50000 THEN 'Medium Performer'
        ELSE 'Low Performer'
    END AS performance_category,
    COUNT(DISTINCT ss.ss_ticket_number) AS total_sales_tickets
FROM 
    RankedSales r
LEFT JOIN 
    store_sales ss ON r.web_site_sk = ss.ss_store_sk
LEFT JOIN 
    warehouse w ON ss.ss_store_sk = w.w_warehouse_sk
WHERE 
    r.rank = 1
GROUP BY 
    r.web_name, r.total_profit, w.w_warehouse_name
HAVING 
    COUNT(DISTINCT ss.ss_ticket_number) > 5
ORDER BY 
    r.total_profit DESC, overall_rank
LIMIT 10;
