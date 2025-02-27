
WITH RECURSIVE sales_data AS (
    SELECT 
        ws.web_site_sk,
        SUM(ws.ws_net_profit) AS total_net_profit,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        ROW_NUMBER() OVER (PARTITION BY ws.web_site_sk ORDER BY SUM(ws.ws_net_profit) DESC) AS rank
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk BETWEEN (SELECT MIN(d.d_date_sk) FROM date_dim d WHERE d.d_year = 2022) AND (SELECT MAX(d.d_date_sk) FROM date_dim d WHERE d.d_year = 2023)
    GROUP BY 
        ws.web_site_sk
),
inventory_data AS (
    SELECT 
        inv.inv_item_sk AS item_sk,
        SUM(inv.inv_quantity_on_hand) AS total_quantity
    FROM 
        inventory inv
    WHERE 
        inv_date_sk = (SELECT MAX(inv_date_sk) FROM inventory)
    GROUP BY 
        inv.inv_item_sk
),
top_sites AS (
    SELECT 
        sd.web_site_sk,
        sd.total_net_profit,
        sd.total_orders,
        ROW_NUMBER() OVER (ORDER BY sd.total_net_profit DESC) AS site_rank
    FROM 
        sales_data sd
    WHERE 
        sd.rank <= 5
)
SELECT 
    s.ws_web_site_id,
    s.total_net_profit,
    s.total_orders,
    CONCAT('Sales Amount: $', CAST(s.total_net_profit AS VARCHAR(20))) AS sales_description,
    COALESCE(i.total_quantity, 0) AS quantity_on_hand,
    CASE 
        WHEN s.total_orders > 100 THEN 'High Activity'
        WHEN s.total_orders BETWEEN 50 AND 100 THEN 'Moderate Activity'
        ELSE 'Low Activity'
    END AS activity_level,
    (SELECT COUNT(*) FROM customer c WHERE c.c_birth_year < 1980 AND c.c_preferred_cust_flag = 'Y') AS total_vintage_customers
FROM 
    top_sites s
LEFT JOIN 
    (SELECT 
         inv_item_sk, 
         SUM(inv_quantity_on_hand) AS total_quantity 
     FROM 
         inventory_data 
     GROUP BY 
         inv_item_sk) i ON i.item_sk IN (SELECT DISTINCT ws_item_sk FROM web_sales WHERE ws_web_site_sk = s.web_site_sk)
JOIN 
    web_site ws ON ws.web_site_sk = s.web_site_sk
WHERE 
    s.total_net_profit IS NOT NULL
ORDER BY 
    s.total_net_profit DESC
FETCH FIRST 10 ROWS ONLY;
