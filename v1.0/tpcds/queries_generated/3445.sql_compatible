
WITH ranked_sales AS (
    SELECT 
        ws.web_site_id,
        SUM(ws.ws_net_profit) AS total_net_profit,
        RANK() OVER (PARTITION BY ws.web_site_id ORDER BY SUM(ws.ws_net_profit) DESC) AS rank
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2023
    GROUP BY 
        ws.web_site_id
),
high_profit_sites AS (
    SELECT 
        web_site_id
    FROM 
        ranked_sales
    WHERE 
        rank <= 5
),
inventory_status AS (
    SELECT 
        i.i_item_sk,
        SUM(i.inv_quantity_on_hand) AS total_quantity_on_hand,
        CASE 
            WHEN SUM(i.inv_quantity_on_hand) = 0 THEN 'Out of Stock'
            ELSE 'In Stock'
        END AS stock_status
    FROM 
        inventory i
    GROUP BY 
        i.i_item_sk
)
SELECT 
    ws.web_site_id,
    SUM(ws.ws_net_profit) AS total_net_profit,
    COUNT(DISTINCT ws.ws_order_number) AS total_orders,
    COALESCE(SUM(i.total_quantity_on_hand), 0) AS total_quantity_on_hand,
    CASE 
        WHEN SUM(ws.ws_net_profit) > 10000 THEN 'High Revenue'
        WHEN SUM(ws.ws_net_profit) BETWEEN 5000 AND 10000 THEN 'Medium Revenue'
        ELSE 'Low Revenue'
    END AS revenue_category,
    STRING_AGG(DISTINCT s.s_store_name, ', ') AS stores
FROM 
    web_sales ws
LEFT JOIN 
    high_profit_sites hps ON ws.ws_web_site_sk = hps.web_site_id
LEFT JOIN 
    inventory_status i ON ws.ws_item_sk = i.i_item_sk
LEFT JOIN 
    store s ON ws.ws_ship_addr_sk = s.s_store_sk
WHERE 
    hps.web_site_id IS NOT NULL
GROUP BY 
    ws.web_site_id
HAVING 
    SUM(ws.ws_net_profit) IS NOT NULL
ORDER BY 
    total_net_profit DESC;
