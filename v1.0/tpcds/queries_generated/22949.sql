
WITH RECURSIVE Sales_CTE AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        SUM(ws_net_profit) AS total_profit,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_net_profit) DESC) AS rank
    FROM web_sales
    GROUP BY ws_sold_date_sk, ws_item_sk
),
Filtered_Sales AS (
    SELECT 
        s.ws_item_sk,
        MAX(s.total_profit) AS max_profit
    FROM Sales_CTE s
    WHERE s.rank <= 10
    GROUP BY s.ws_item_sk
),
Inventory_Stats AS (
    SELECT 
        inv.inv_item_sk,
        AVG(inv.inv_quantity_on_hand) AS avg_quantity,
        SUM(CASE WHEN inv.inv_quantity_on_hand IS NULL THEN 1 ELSE 0 END) AS null_quantity_count
    FROM inventory inv
    GROUP BY inv.inv_item_sk
    HAVING AVG(inv.inv_quantity_on_hand) > 0
),
Sales_Comparison AS (
    SELECT 
        fs.ws_item_sk,
        fs.max_profit,
        is.avg_quantity,
        is.null_quantity_count
    FROM Filtered_Sales fs
    JOIN Inventory_Stats is ON fs.ws_item_sk = is.inv_item_sk
),
Joined_Data AS (
    SELECT
        sc.ws_item_sk,
        sc.max_profit,
        sc.avg_quantity,
        sc.null_quantity_count,
        COALESCE(co.c_customer_id, 'Unknown') AS customer_id,
        COALESCE(cc.cc_class, 'Unclassified') AS call_center_class
    FROM Sales_Comparison sc
    LEFT JOIN customer c ON c.c_customer_sk = (SELECT c_customer_sk FROM web_sales WHERE ws_item_sk = sc.ws_item_sk LIMIT 1)
    LEFT JOIN call_center cc ON cc.cc_call_center_sk = (SELECT cc_closed_date_sk FROM store_returns sr WHERE sr.sr_item_sk = sc.ws_item_sk LIMIT 1)
)
SELECT 
    jd.ws_item_sk,
    jd.max_profit,
    jd.avg_quantity,
    jd.null_quantity_count,
    CONCAT('Item ', jd.ws_item_sk) AS item_description,
    jd.customer_id,
    jd.call_center_class
FROM Joined_Data jd
WHERE jd.null_quantity_count > 0 
ORDER BY jd.max_profit DESC, jd.avg_quantity ASC
LIMIT 50;
