
WITH RECURSIVE CustomerAddressCTE AS (
    SELECT ca_address_sk, ca_city, ca_state, ca_country, 1 AS level
    FROM customer_address
    WHERE ca_state IS NOT NULL

    UNION ALL

    SELECT ca_address_sk, ca_city, ca_state, ca_country, cte.level + 1
    FROM customer_address cte
    JOIN customer_address addr ON cte.ca_city = addr.ca_city AND cte.level < 5
)
, InventoryStatistics AS (
    SELECT 
        inv.inv_warehouse_sk,
        SUM(inv.inv_quantity_on_hand) AS total_quantity,
        AVG(CASE WHEN inv.inv_quantity_on_hand IS NOT NULL THEN inv.inv_quantity_on_hand ELSE 0 END) AS avg_quantity,
        COUNT(DISTINCT inv.inv_item_sk) AS unique_items
    FROM inventory inv
    GROUP BY inv.inv_warehouse_sk
)
, WebSaleAnalysis AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        MAX(ws.ws_sales_price) AS max_sales_price,
        MIN(ws.ws_sales_price) AS min_sales_price
    FROM web_sales ws
    WHERE ws.ws_sales_price IS NOT NULL
    GROUP BY ws.ws_item_sk
)
, StoreSalesAnalysis AS (
    SELECT 
        ss.ss_item_sk,
        SUM(ss.ss_sales_price) AS total_store_sales,
        COUNT(DISTINCT ss.ss_ticket_number) AS store_orders
    FROM store_sales ss
    WHERE ss.ss_sales_price < (SELECT AVG(ws_sales_price) FROM web_sales WHERE ws_sales_price IS NOT NULL) OR ss.ss_sales_price IS NULL
    GROUP BY ss.ss_item_sk
)
SELECT 
    c.c_customer_id,
    ctx.ca_city,
    ctx.ca_state,
    SUM(s.total_store_sales) AS total_sales_from_stores,
    SUM(w.total_sales) AS total_sales_from_web,
    COALESCE(SUM(i.total_quantity), 0) AS total_inventory,
    CASE 
        WHEN state_count >= 50 THEN 'High Density'
        WHEN state_count BETWEEN 10 AND 50 THEN 'Medium Density'
        ELSE 'Low Density'
    END AS density_category
FROM customer c
INNER JOIN customer_address ctx ON c.c_current_addr_sk = ctx.ca_address_sk 
LEFT JOIN InventoryStatistics i ON ctx.ca_address_sk = i.inv_warehouse_sk
LEFT JOIN WebSaleAnalysis w ON ctx.ca_address_sk = w.ws_item_sk
LEFT JOIN StoreSalesAnalysis s ON ctx.ca_address_sk = s.ss_item_sk
LEFT JOIN (
    SELECT ca_state, COUNT(DISTINCT ca_city) AS state_count
    FROM customer_address
    GROUP BY ca_state
) AS state_counts ON ctx.ca_state = state_counts.ca_state
GROUP BY c.c_customer_id, ctx.ca_city, ctx.ca_state, state_count
HAVING SUM(s.total_store_sales) > 1000 AND SUM(w.total_sales) IS DISTINCT FROM 0
ORDER BY total_sales_from_stores DESC, total_sales_from_web DESC;
