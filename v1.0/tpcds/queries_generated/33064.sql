
WITH RECURSIVE SalesHierarchy AS (
    SELECT s_store_sk, s_store_name, 0 AS level, NULL AS parent_store_sk
    FROM store 
    WHERE s_store_sk IS NOT NULL
    UNION ALL
    SELECT s.store_sk, s.s_store_name, sh.level + 1, sh.s_store_sk
    FROM store s
    JOIN SalesHierarchy sh ON s.s_closed_date_sk < sh.level
),
AggregateSales AS (
    SELECT 
        w.w_warehouse_id, 
        COALESCE(SUM(ws.ws_net_profit), 0) AS total_profit,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM warehouse w
    LEFT JOIN web_sales ws ON w.w_warehouse_sk = ws.ws_warehouse_sk
    GROUP BY w.w_warehouse_id
),
CustomerSegments AS (
    SELECT 
        cd.cd_gender, 
        COUNT(c.c_customer_sk) AS customer_count,
        AVG(cd.cd_purchase_estimate) AS average_purchase_estimate
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY cd.cd_gender
)
SELECT 
    sh.level, 
    sh.s_store_name,
    asales.w_warehouse_id,
    asales.total_profit,
    cs.cd_gender,
    cs.customer_count,
    cs.average_purchase_estimate
FROM SalesHierarchy sh
LEFT JOIN AggregateSales asales ON sh.s_store_sk = asales.w_warehouse_sk
FULL OUTER JOIN CustomerSegments cs ON sh.level = cs.customer_count
WHERE asales.total_profit > 1000 
    OR cs.customer_count IS NOT NULL
ORDER BY sh.level, asales.total_profit DESC, cs.customer_count DESC;
