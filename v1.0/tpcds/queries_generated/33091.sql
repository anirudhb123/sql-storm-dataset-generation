
WITH RECURSIVE sales_cte AS (
    SELECT 
        ws.web_site_sk,
        ws.web_site_id,
        SUM(ws.ws_net_profit) AS total_net_profit,
        RANK() OVER (PARTITION BY ws.web_site_id ORDER BY SUM(ws.ws_net_profit) DESC) AS profit_rank
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_ship_customer_sk = c.c_customer_sk
    WHERE 
        c.c_birth_month = 12
    GROUP BY 
        ws.web_site_sk, ws.web_site_id
),
max_profit AS (
    SELECT 
        MAX(total_net_profit) AS max_profit
    FROM 
        sales_cte
),
inventory_cte AS (
    SELECT 
        inv.inv_item_sk,
        SUM(inv.inv_quantity_on_hand) AS total_quantity,
        ROW_NUMBER() OVER (ORDER BY SUM(inv.inv_quantity_on_hand) DESC) AS quantity_rank
    FROM 
        inventory inv
    GROUP BY 
        inv.inv_item_sk
),
excess_sales AS (
    SELECT 
        cs.cs_item_sk,
        SUM(cs.cs_net_paid) AS total_sales
    FROM 
        catalog_sales cs
    WHERE 
        cs.cs_sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        cs.cs_item_sk
    HAVING 
        SUM(cs.cs_net_paid) > (SELECT max_profit FROM max_profit)
)
SELECT 
    i.i_item_id,
    i.i_product_name,
    COALESCE(inv.total_quantity, 0) AS available_inventory,
    COALESCE(es.total_sales, 0) AS sales_excess,
    s.total_net_profit,
    s.web_site_id
FROM 
    item i
LEFT JOIN 
    inventory_cte inv ON i.i_item_sk = inv.inv_item_sk
LEFT JOIN 
    excess_sales es ON i.i_item_sk = es.cs_item_sk
INNER JOIN 
    sales_cte s ON s.web_site_sk = (SELECT ws.web_site_sk FROM web_sales ws WHERE ws.ws_item_sk = i.i_item_sk LIMIT 1)
WHERE 
    (inv.total_quantity IS NULL OR inv.total_quantity < 100)
    AND es.total_sales IS NOT NULL
ORDER BY 
    s.total_net_profit DESC, available_inventory ASC
OFFSET 5 ROWS FETCH NEXT 10 ROWS ONLY;
