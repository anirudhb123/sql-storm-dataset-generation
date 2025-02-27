
WITH recursive return_stats AS (
    SELECT
        ws_item_sk,
        SUM(ws_return_quantity) AS total_returns,
        COUNT(DISTINCT ws_order_number) AS return_orders,
        NULLIF(SUM(ws_return_amt), 0) AS total_return_amt,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_return_amt) DESC) AS rn
    FROM (
        SELECT 
            wr_item_sk, 
            wr_return_quantity, 
            wr_return_amt, 
            wr_order_number
        FROM web_returns
        UNION ALL
        SELECT 
            cr_item_sk, 
            cr_return_quantity, 
            cr_return_amount, 
            cr_order_number
        FROM catalog_returns
    ) AS combined_returns
    GROUP BY ws_item_sk
),
inventory_stats AS (
    SELECT 
        inv_item_sk,
        SUM(inv_quantity_on_hand) AS total_inventory,
        COUNT(DISTINCT inv_warehouse_sk) AS warehouse_count
    FROM inventory
    GROUP BY inv_item_sk
),
negative_profit_items AS (
    SELECT
        ss_item_sk,
        SUM(ss_net_profit) AS total_net_profit
    FROM store_sales
    GROUP BY ss_item_sk
    HAVING SUM(ss_net_profit) < 0
),
final_report AS (
    SELECT 
        i.i_item_id,
        i.i_item_desc,
        is.total_inventory,
        rs.total_returns,
        rs.return_orders,
        COALESCE(rs.total_return_amt, 0) AS total_return_amt,
        CASE 
            WHEN fi.total_net_profit IS NULL THEN 0 
            ELSE fi.total_net_profit 
        END AS total_negative_profit
    FROM item i
    LEFT JOIN inventory_stats is ON i.i_item_sk = is.inv_item_sk
    LEFT JOIN return_stats rs ON i.i_item_sk = rs.ws_item_sk
    LEFT JOIN negative_profit_items fi ON i.i_item_sk = fi.ss_item_sk
    WHERE i.i_current_price > 100.00 
      AND (rs.return_orders IS NULL OR rs.return_orders > 1
           OR ISNULL(rs.return_orders, 0) > 1)  -- Demonstrating NULL logic
)
SELECT 
    f.i_item_id,
    f.i_item_desc,
    f.total_inventory,
    f.total_returns,
    f.return_orders,
    ROUND(f.total_return_amt, 2) AS formatted_return_amt,
    CASE 
        WHEN f.total_negative_profit < 0 THEN 'Negative Profit'
        ELSE 'Positive Profit'
    END AS profit_status
FROM final_report f
ORDER BY f.total_inventory DESC, f.total_returns DESC, f.i_item_id;
