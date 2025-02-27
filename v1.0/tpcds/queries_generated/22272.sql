
WITH RECURSIVE ItemHierarchy AS (
    SELECT i_item_sk, i_item_desc, i_brand, i_manager_id, 1 AS level
    FROM item
    WHERE i_current_price > 100.00
    UNION ALL
    SELECT i.i_item_sk, i.i_item_desc, i.i_brand, ih.i_manager_id, ih.level + 1
    FROM item i
    JOIN ItemHierarchy ih ON i.i_manager_id = ih.i_item_sk
    WHERE i.i_current_price IS NOT NULL OR ih.level < 10
),
SalesStats AS (
    SELECT 
        d.d_year,
        SUM(ws.ws_net_profit) AS total_profit,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        AVG(ws.ws_net_paid_inc_tax) AS avg_order_value
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE d.d_year BETWEEN 2020 AND 2023
    GROUP BY d.d_year
),
WarehouseStats AS (
    SELECT 
        w.w_warehouse_id,
        AVG(ws.ws_net_profit) AS avg_profit_per_item,
        COUNT(DISTINCT ws.ws_item_sk) AS unique_items
    FROM warehouse w
    LEFT JOIN web_sales ws ON w.w_warehouse_sk = ws.ws_warehouse_sk
    GROUP BY w.w_warehouse_id
),
TotalSales AS (
    SELECT 
        COALESCE(SUM(total_orders), 0) AS overall_order_count,
        COALESCE(SUM(total_profit), 0) AS overall_profit
    FROM SalesStats
)

SELECT 
    rh.i_item_desc,
    rh.i_brand,
    CASE 
        WHEN w.avg_profit_per_item IS NULL THEN 'No Sales'
        ELSE TO_CHAR(w.avg_profit_per_item, 'FM$999,999,990.00')
    END AS avg_profit_per_item,
    ts.overall_order_count,
    ts.overall_profit,
    ROW_NUMBER() OVER (PARTITION BY rh.i_brand ORDER BY rh.level DESC) AS rank_by_level
FROM ItemHierarchy rh
LEFT JOIN WarehouseStats w ON rh.i_item_sk = w.w_warehouse_id
CROSS JOIN TotalSales ts
WHERE rh.level <= 5
ORDER BY rh.i_item_desc ASC, rank_by_level DESC
FETCH FIRST 100 ROWS ONLY;
