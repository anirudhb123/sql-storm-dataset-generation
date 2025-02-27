
WITH RECURSIVE customer_hierarchy AS (
    SELECT c_customer_sk, c_first_name, c_last_name, c_current_cdemo_sk, 0 AS level
    FROM customer
    WHERE c_customer_sk IS NOT NULL
    
    UNION ALL
    
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, c.c_current_cdemo_sk, ch.level + 1
    FROM customer c
    JOIN customer_hierarchy ch ON c.c_current_cdemo_sk = ch.c_current_cdemo_sk
    WHERE ch.level < 5
),
inventory_summary AS (
    SELECT inv.inv_item_sk, SUM(inv.inv_quantity_on_hand) AS total_quantity
    FROM inventory inv
    WHERE inv.inv_quantity_on_hand IS NOT NULL
    GROUP BY inv.inv_item_sk
),
sales_summary AS (
    SELECT 
        ws.ws_item_sk,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_sales_price) AS total_sales,
        AVG(ws.ws_net_profit) AS avg_net_profit
    FROM web_sales ws
    WHERE ws.ws_sold_date_sk BETWEEN 1 AND 365
    GROUP BY ws.ws_item_sk
),
return_summary AS (
    SELECT 
        cr.cr_item_sk,
        COUNT(cr.cr_order_number) AS total_returns,
        SUM(cr.cr_return_amount) AS total_return_amount
    FROM catalog_returns cr
    GROUP BY cr.cr_item_sk
),
combined_summary AS (
    SELECT 
        is.inv_item_sk,
        COALESCE(ss.total_orders, 0) AS total_orders,
        COALESCE(ss.total_sales, 0) AS total_sales,
        COALESCE(ss.avg_net_profit, 0) AS avg_net_profit,
        COALESCE(rs.total_returns, 0) AS total_returns,
        COALESCE(rs.total_return_amount, 0) AS total_return_amount,
        CASE 
            WHEN COALESCE(ss.total_sales, 0) = 0 THEN NULL
            ELSE (COALESCE(rs.total_return_amount, 0) / COALESCE(ss.total_sales, 0)) * 100 
        END AS return_rate_percentage
    FROM inventory_summary is
    LEFT JOIN sales_summary ss ON is.inv_item_sk = ss.ws_item_sk
    LEFT JOIN return_summary rs ON is.inv_item_sk = rs.cr_item_sk
)
SELECT 
    ch.c_first_name,
    ch.c_last_name,
    cs.inv_item_sk,
    cs.total_orders,
    cs.total_sales,
    cs.avg_net_profit,
    cs.total_returns,
    cs.total_return_amount,
    cs.return_rate_percentage
FROM combined_summary cs
JOIN customer_hierarchy ch ON ch.c_current_cdemo_sk = (SELECT MAX(cd_demo_sk) FROM customer_demographics WHERE cd_demo_sk = ch.c_current_cdemo_sk)
WHERE cs.total_orders > 0
ORDER BY cs.total_sales DESC
LIMIT 10;
