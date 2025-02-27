
WITH RECURSIVE sales_data AS (
    SELECT 
        ws.web_site_sk, 
        ws.ws_order_number, 
        SUM(ws.ws_net_profit) AS total_profit, 
        RANK() OVER (PARTITION BY ws.web_site_sk ORDER BY SUM(ws.ws_net_profit) DESC) AS profit_rank
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk BETWEEN (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023) - 30 AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        ws.web_site_sk, ws.ws_order_number
    HAVING 
        SUM(ws.ws_net_profit) > 0
), ranked_sales AS (
    SELECT 
        sd.web_site_sk, 
        sd.ws_order_number, 
        sd.total_profit,
        CASE 
            WHEN sd.profit_rank <= 10 THEN 'Top'
            WHEN sd.profit_rank BETWEEN 11 AND 50 THEN 'Medium'
            ELSE 'Low'
        END AS profit_category
    FROM sales_data sd
)
SELECT 
    wa.warehouse_name, 
    COUNT(DISTINCT rs.ws_order_number) AS order_count,
    AVG(rs.total_profit) AS avg_profit,
    MAX(rs.total_profit) AS max_profit,
    MIN(rs.total_profit) AS min_profit
FROM 
    ranked_sales rs
LEFT JOIN 
    warehouse wa ON rs.web_site_sk = wa.w_warehouse_sk
GROUP BY 
    wa.warehouse_name
HAVING 
    COUNT(DISTINCT rs.ws_order_number) > 0
ORDER BY 
    avg_profit DESC
LIMIT 5;
