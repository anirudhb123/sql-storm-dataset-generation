
WITH RECURSIVE InventoryHistory AS (
    SELECT 
        inv_date_sk, 
        inv_item_sk, 
        inv_warehouse_sk, 
        inv_quantity_on_hand 
    FROM inventory 
    WHERE inv_date_sk <= (SELECT MAX(inv_date_sk) FROM inventory)
    
    UNION ALL
    
    SELECT 
        ih.inv_date_sk - 1, 
        ih.inv_item_sk, 
        ih.inv_warehouse_sk, 
        ih.inv_quantity_on_hand + (CASE 
                                        WHEN ih.inv_quantity_on_hand IS NULL THEN 0 
                                        ELSE ih.inv_quantity_on_hand 
                                    END) 
    FROM InventoryHistory ih
    WHERE ih.inv_date_sk > 1
),
AggregatedSales AS (
    SELECT
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_paid) AS total_net_paid,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_net_paid) DESC) AS sales_rank
    FROM web_sales
    GROUP BY ws_item_sk
),
FilteredSales AS (
    SELECT 
        asales.ws_item_sk, 
        asales.total_quantity, 
        asales.total_net_paid 
    FROM AggregatedSales asales
    WHERE asales.sales_rank <= 10
),
CustomerMetrics AS (
    SELECT 
        cd.cd_gender,
        COUNT(DISTINCT c.c_customer_id) AS customer_count,
        AVG(cd.cd_purchase_estimate) AS avg_purchase
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY cd.cd_gender
)
SELECT 
    wa.w_warehouse_id,
    wa.w_warehouse_name,
    COALESCE(IH.inv_quantity_on_hand, 0) AS current_inventory_quantity,
    FS.total_quantity AS total_sales_quantity,
    FS.total_net_paid AS total_sales_value,
    CM.cd_gender,
    CM.customer_count,
    CM.avg_purchase
FROM warehouse wa
LEFT JOIN InventoryHistory IH ON wa.w_warehouse_sk = IH.inv_warehouse_sk
LEFT JOIN FilteredSales FS ON FS.ws_item_sk = IH.inv_item_sk
LEFT JOIN CustomerMetrics CM ON CM.cd_gender IS NOT NULL
WHERE (IH.inv_quantity_on_hand IS NOT NULL OR FS.total_quantity IS NOT NULL)
ORDER BY wa.w_warehouse_id, FS.total_net_paid DESC;
