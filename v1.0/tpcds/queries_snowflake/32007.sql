
WITH RECURSIVE CTE_SALES AS (
    SELECT 
        s.ss_item_sk,
        s.ss_ticket_number,
        s.ss_sold_date_sk,
        SUM(s.ss_net_profit) AS total_profit,
        ROW_NUMBER() OVER (PARTITION BY s.ss_item_sk ORDER BY SUM(s.ss_net_profit) DESC) as rn
    FROM 
        store_sales s
    GROUP BY 
        s.ss_item_sk, s.ss_ticket_number, s.ss_sold_date_sk
    HAVING 
        SUM(s.ss_net_profit) > 0
    UNION ALL
    SELECT 
        c.cs_item_sk,
        c.cs_order_number,
        c.cs_sold_date_sk,
        SUM(c.cs_net_profit) AS total_profit,
        ROW_NUMBER() OVER (PARTITION BY c.cs_item_sk ORDER BY SUM(c.cs_net_profit) DESC) as rn
    FROM 
        catalog_sales c
    GROUP BY 
        c.cs_item_sk, c.cs_order_number, c.cs_sold_date_sk
    HAVING 
        SUM(c.cs_net_profit) > 0
)
SELECT 
    ia.i_item_id,
    COALESCE(non_zero_sales.total_profit, 0) AS total_profit,
    COALESCE(non_zero_sales.rn, 0) AS rank,
    (SELECT COUNT(*) FROM inventory inv WHERE inv.inv_quantity_on_hand > 0) AS total_items_available,
    w.w_warehouse_name
FROM 
    item ia
LEFT JOIN (
    SELECT 
        ss.ss_item_sk,
        ss.ss_sold_date_sk,
        SUM(ss.ss_net_profit) AS total_profit,
        ROW_NUMBER() OVER (PARTITION BY ss.ss_item_sk ORDER BY SUM(ss.ss_net_profit) DESC) as rn
    FROM 
        store_sales ss
    GROUP BY 
        ss.ss_item_sk, ss.ss_sold_date_sk
    HAVING 
        SUM(ss.ss_net_profit) > 0
) non_zero_sales ON ia.i_item_sk = non_zero_sales.ss_item_sk
JOIN warehouse w ON w.w_warehouse_sk = (SELECT inv.inv_warehouse_sk FROM inventory inv WHERE inv.inv_item_sk = ia.i_item_sk ORDER BY inv.inv_quantity_on_hand DESC LIMIT 1)
WHERE 
    ia.i_current_price IS NOT NULL
ORDER BY 
    total_profit DESC
LIMIT 50;
