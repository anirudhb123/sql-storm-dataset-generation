
WITH ranked_sales AS (
    SELECT 
        ws.web_site_sk,
        ws.item_sk,
        SUM(ws.net_profit) AS total_profit,
        RANK() OVER (PARTITION BY ws.web_site_sk ORDER BY SUM(ws.net_profit) DESC) AS profit_rank
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.bill_customer_sk = c.c_customer_sk
    WHERE 
        c.c_birth_year > 1970 AND
        (c.c_first_name LIKE 'A%' OR 
        c.c_last_name LIKE 'B%')
    GROUP BY 
        ws.web_site_sk, ws.item_sk
), above_average_sales AS (
    SELECT 
        item_sk,
        total_profit
    FROM 
        ranked_sales
    WHERE 
        profit_rank = 1
        AND total_profit > (SELECT AVG(total_profit) FROM ranked_sales)
), low_supply AS (
    SELECT 
        inv.item_sk,
        SUM(inv.inv_quantity_on_hand) AS total_inventory
    FROM 
        inventory inv
    LEFT JOIN 
        above_average_sales a ON inv.item_sk = a.item_sk
    WHERE 
        a.item_sk IS NULL
    GROUP BY 
        inv.item_sk
), final_benchmark AS (
    SELECT 
        ws.web_site_sk,
        ws.item_sk,
        SUM(ws.ws_quantity) AS total_sold,
        COALESCE(ls.total_inventory, 0) AS inventory_shortage
    FROM 
        web_sales ws
    LEFT JOIN 
        low_supply ls ON ws.item_sk = ls.item_sk
    GROUP BY 
        ws.web_site_sk, ws.item_sk
    HAVING 
        total_sold > 100 
    ORDER BY 
        total_sold DESC
)
SELECT 
    wb.web_name,
    fb.item_sk,
    fb.total_sold,
    fb.inventory_shortage,
    CASE 
        WHEN fb.inventory_shortage < 10 THEN 'Low Supply'
        WHEN fb.inventory_shortage BETWEEN 10 AND 50 THEN 'Moderate Supply'
        ELSE 'High Supply'
    END AS supply_status
FROM 
    final_benchmark fb
JOIN 
    web_site wb ON fb.web_site_sk = wb.web_site_sk
WHERE 
    wb.web_country IS NOT NULL
    AND wb.web_gmt_offset >= 0
    AND EXISTS (
        SELECT 1 
        FROM promotion p 
        WHERE p.p_item_sk = fb.item_sk
        AND p.p_discount_active = 'Y'
    )
ORDER BY 
    supply_status, total_sold DESC;
