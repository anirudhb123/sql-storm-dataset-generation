
WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_quantity,
        ws.ws_net_paid,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_net_paid DESC) as rank
    FROM 
        web_sales ws
    WHERE 
        ws.ws_net_paid > (SELECT AVG(ws2.ws_net_paid) 
                           FROM web_sales ws2 
                           WHERE ws2.ws_item_sk = ws.ws_item_sk)
),
CustomerReturns AS (
    SELECT 
        cr.returning_customer_sk AS customer_sk,
        COALESCE(SUM(cr.cr_return_quantity), 0) AS total_return_qty,
        COUNT(DISTINCT cr.cr_order_number) AS total_returns
    FROM 
        catalog_returns cr
    WHERE 
        cr.cr_return_quantity IS NOT NULL 
        AND cr.cr_return_quantity > 0
    GROUP BY 
        cr.returning_customer_sk
    HAVING 
        total_return_qty > (SELECT AVG(total_return_qty) 
                             FROM (SELECT 
                                       COUNT(*) AS total_return_qty 
                                   FROM catalog_returns 
                                   GROUP BY returning_customer_sk) AS avg_returns)
),
StoreInventory AS (
    SELECT 
        inv.inv_item_sk,
        SUM(inv.inv_quantity_on_hand) AS total_quantity
    FROM 
        inventory inv
    GROUP BY 
        inv.inv_item_sk
),
FinalReport AS (
    SELECT 
        c.c_customer_id,
        ra.ws_item_sk,
        ra.ws_order_number,
        ra.ws_quantity,
        ra.ws_net_paid,
        ci.total_return_qty,
        si.total_quantity
    FROM 
        RankedSales ra
    JOIN 
        customer c ON ra.ws_order_number = c.c_customer_sk
    LEFT JOIN 
        CustomerReturns ci ON ci.customer_sk = c.c_customer_sk
    LEFT JOIN 
        StoreInventory si ON si.inv_item_sk = ra.ws_item_sk
    WHERE 
        (si.total_quantity IS NULL OR si.total_quantity > 100) 
        AND (ci.total_return_qty IS NULL OR ci.total_return_qty < 5)
)
SELECT 
    fr.c_customer_id,
    fr.ws_item_sk,
    fr.ws_order_number,
    fr.ws_quantity,
    fr.ws_net_paid,
    CASE 
        WHEN fr.total_return_qty IS NULL THEN 'No Returns'
        WHEN fr.total_return_qty < 2 THEN 'Low Returns'
        ELSE 'Frequent Returns'
    END AS return_category,
    CASE 
        WHEN fr.total_quantity IS NULL THEN 'No Inventory'
        WHEN fr.total_quantity < 50 THEN 'Low Inventory'
        ELSE 'Adequate Inventory'
    END AS inventory_status
FROM 
    FinalReport fr
ORDER BY 
    fr.ws_net_paid DESC NULLS LAST;
