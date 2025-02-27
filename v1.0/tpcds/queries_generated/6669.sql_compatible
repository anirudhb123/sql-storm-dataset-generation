
WITH sales_summary AS (
    SELECT 
        ws.web_site_id,
        i.i_item_id,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_profit) AS total_net_profit,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM 
        web_sales ws
    JOIN 
        item i ON ws.ws_item_sk = i.i_item_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year = 2023 AND 
        ws.ws_net_profit > 0
    GROUP BY 
        ws.web_site_id, i.i_item_id
),
high_performance_items AS (
    SELECT 
        web_site_id, 
        i_item_id, 
        total_quantity,
        total_net_profit,
        total_sales,
        total_orders,
        RANK() OVER (PARTITION BY web_site_id ORDER BY total_net_profit DESC) AS net_profit_rank
    FROM 
        sales_summary
)
SELECT 
    w.web_site_id,
    w.web_name,
    hpi.i_item_id,
    hpi.total_quantity,
    hpi.total_net_profit,
    hpi.total_sales,
    hpi.total_orders
FROM 
    high_performance_items hpi
JOIN 
    web_site w ON hpi.web_site_id = w.web_site_id
WHERE 
    hpi.net_profit_rank <= 10
ORDER BY 
    w.web_site_id, hpi.total_net_profit DESC;
