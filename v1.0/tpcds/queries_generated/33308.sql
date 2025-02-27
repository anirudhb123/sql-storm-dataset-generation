
WITH RECURSIVE SalesGrowth AS (
    SELECT 
        w.w_warehouse_id,
        SUM(ss_net_profit) AS total_profit,
        1 AS growth_level
    FROM 
        warehouse w
    JOIN store_sales ss ON w.w_warehouse_sk = ss.ss_store_sk
    GROUP BY 
        w.w_warehouse_id

    UNION ALL

    SELECT 
        w.w_warehouse_id,
        SUM(ss.ss_net_profit) * 1.1 AS total_profit, 
        growth_level + 1
    FROM 
        warehouse w
    JOIN store_sales ss ON w.w_warehouse_sk = ss.ss_store_sk
    JOIN SalesGrowth sg ON w.w_warehouse_id = sg.w_warehouse_id 
    WHERE 
        sg.growth_level < 5
    GROUP BY 
        w.w_warehouse_id
),
CustomerHistogram AS (
    SELECT 
        CASE 
            WHEN cd_purchase_estimate < 10000 THEN 'Low'
            WHEN cd_purchase_estimate BETWEEN 10000 AND 50000 THEN 'Medium'
            ELSE 'High'
        END AS purchase_band,
        COUNT(*) AS customer_count
    FROM 
        customer_demographics
    GROUP BY 
        purchase_band
),
InventoryReport AS (
    SELECT 
        i.i_item_id, 
        SUM(i.inv_quantity_on_hand) AS total_quantity,
        ROW_NUMBER() OVER (PARTITION BY i.i_item_id ORDER BY SUM(i.inv_quantity_on_hand) DESC) AS rn
    FROM 
        inventory i
    GROUP BY 
        i.i_item_id
)
SELECT 
    sg.w_warehouse_id,
    sg.total_profit,
    ch.purchase_band,
    ir.i_item_id,
    ir.total_quantity
FROM 
    SalesGrowth sg
LEFT JOIN 
    CustomerHistogram ch ON sg.total_profit > 10000
JOIN 
    InventoryReport ir ON ir.rn <= 10
WHERE 
    sg.total_profit IS NOT NULL
ORDER BY 
    sg.total_profit DESC, ch.customer_count;
