
WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_paid) AS total_net_paid,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_net_paid) DESC) AS rank
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year = 2023
    GROUP BY 
        ws.ws_item_sk, ws.ws_order_number
),
StoreProfits AS (
    SELECT 
        ss.ss_store_sk,
        SUM(ss.ss_net_profit) AS store_profit
    FROM 
        store_sales ss
    JOIN 
        store s ON ss.ss_store_sk = s.s_store_sk
    WHERE 
        s.s_state = 'CA'
    GROUP BY 
        ss.ss_store_sk
),
InventoryStatus AS (
    SELECT 
        inv.inv_item_sk,
        SUM(inv.inv_quantity_on_hand) AS total_inventory
    FROM 
        inventory inv
    GROUP BY 
        inv.inv_item_sk
)
SELECT 
    i.i_item_id,
    i.i_item_desc,
    rs.total_quantity,
    rs.total_net_paid,
    sp.store_profit,
    CASE 
        WHEN is.total_inventory IS NULL THEN 'Out of Stock'
        WHEN is.total_inventory < 10 THEN 'Low Stock'
        ELSE 'In Stock'
    END AS stock_status
FROM 
    item i
LEFT JOIN 
    RankedSales rs ON i.i_item_sk = rs.ws_item_sk AND rs.rank = 1
LEFT JOIN 
    StoreProfits sp ON sp.ss_store_sk = (
        SELECT 
            ss.ss_store_sk
        FROM 
            store_sales ss
        WHERE 
            ss.ss_item_sk = i.i_item_sk
        ORDER BY 
            ss.ss_net_profit DESC
        LIMIT 1
    )
LEFT JOIN 
    InventoryStatus is ON i.i_item_sk = is.inv_item_sk
WHERE 
    i.i_current_price > (
        SELECT 
            AVG(i2.i_current_price)
            FROM item i2
            WHERE i2.i_category = i.i_category
        )
ORDER BY 
    total_net_paid DESC
LIMIT 100;
