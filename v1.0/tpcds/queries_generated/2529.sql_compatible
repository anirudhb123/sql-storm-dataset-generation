
WITH ranked_sales AS (
    SELECT 
        ws.web_site_sk,
        ws.web_site_id,
        SUM(ws.ws_net_profit) AS total_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws.web_site_sk ORDER BY SUM(ws.ws_net_profit) DESC) AS rnk
    FROM 
        web_sales ws 
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk 
    WHERE 
        c.c_birth_year BETWEEN 1980 AND 1990 
        AND c.c_preferred_cust_flag = 'Y'
    GROUP BY 
        ws.web_site_sk, ws.web_site_id
),
inventory_summary AS (
    SELECT 
        inv.inv_warehouse_sk,
        SUM(inv.inv_quantity_on_hand) AS total_quantity
    FROM 
        inventory inv
    JOIN 
        warehouse w ON inv.inv_warehouse_sk = w.w_warehouse_sk
    WHERE 
        inv.inv_quantity_on_hand IS NOT NULL
    GROUP BY 
        inv.inv_warehouse_sk
),
sales_and_inventory AS (
    SELECT 
        rss.web_site_id,
        ris.total_quantity,
        rss.total_net_profit
    FROM 
        ranked_sales rss
    LEFT JOIN 
        inventory_summary ris ON rss.web_site_sk = ris.inv_warehouse_sk
    WHERE 
        rss.rnk = 1
)
SELECT 
    sai.web_site_id,
    COALESCE(sai.total_net_profit, 0) AS total_net_profit,
    COALESCE(sai.total_quantity, 0) AS total_inventory,
    (COALESCE(sai.total_net_profit, 0) / NULLIF(sai.total_quantity, 0)) AS net_profit_per_item
FROM 
    sales_and_inventory sai
ORDER BY 
    total_net_profit DESC;
