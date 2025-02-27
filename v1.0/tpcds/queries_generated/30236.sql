
WITH RECURSIVE Inventory_CTE AS (
    SELECT 
        inv_date_sk,
        inv_item_sk,
        inv_warehouse_sk,
        inv_quantity_on_hand,
        1 AS level
    FROM inventory 
    WHERE inv_quantity_on_hand > 0 

    UNION ALL

    SELECT 
        inv.inv_date_sk,
        inv.inv_item_sk,
        inv.inv_warehouse_sk,
        inv.inv_quantity_on_hand - 10 AS inv_quantity_on_hand,
        level + 1
    FROM inventory inv
    JOIN Inventory_CTE cte ON cte.inv_item_sk = inv.inv_item_sk 
    WHERE inv.inv_quantity_on_hand > 0 AND level < 5
), Customer_Summary AS (
    SELECT 
        c.c_customer_sk,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        SUM(ws.ws_net_profit) AS total_profit,
        MAX(cd.cd_purchase_estimate) AS max_purchase_estimate,
        STRING_AGG(DISTINCT CASE WHEN cd.cd_gender = 'M' THEN 'Male' ELSE 'Female' END, ', ') AS gender_distribution
    FROM customer c
    JOIN web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY c.c_customer_sk
)
SELECT 
    ca.ca_address_id,
    cs.c_customer_sk,
    cs.order_count,
    cs.total_profit,
    cs.max_purchase_estimate,
    CASE 
        WHEN cs.total_profit IS NULL THEN 'No Profit'
        WHEN cs.total_profit < 0 THEN 'Loss'
        ELSE 'Profit'
    END AS profit_status,
    ROW_NUMBER() OVER (PARTITION BY cs.order_count ORDER BY cs.total_profit DESC) AS ranking
FROM Customer_Summary cs
JOIN customer_address ca ON cs.c_customer_sk = ca.ca_address_sk
LEFT JOIN (
    SELECT 
        wr_returning_customer_sk,
        SUM(wr_return_amt) AS total_returns
    FROM web_returns
    GROUP BY wr_returning_customer_sk
) wr ON cs.c_customer_sk = wr.wr_returning_customer_sk
WHERE cs.order_count > 0
ORDER BY cs.total_profit DESC
LIMIT 100;
