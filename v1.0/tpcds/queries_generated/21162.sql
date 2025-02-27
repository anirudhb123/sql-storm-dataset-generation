
WITH ranked_customers AS (
    SELECT 
        c.c_customer_sk,
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_zip AS demographic_zip,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS rank_by_estimate
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
high_value_customers AS (
    SELECT 
        rc.c_customer_sk,
        rc.c_customer_id,
        rc.cd_gender,
        rc.demographic_zip,
        COALESCE((
            SELECT AVG(ws.ws_sales_price) 
            FROM web_sales ws 
            WHERE ws.ws_bill_customer_sk = rc.c_customer_sk
        ), 0) AS avg_spent
    FROM ranked_customers rc
    WHERE rc.rank_by_estimate <= 50
),
store_sales_summary AS (
    SELECT 
        ss.ss_store_sk,
        SUM(ss.ss_net_profit) AS total_store_profit,
        COUNT(DISTINCT ss.ss_customer_sk) AS distinct_customers
    FROM store_sales ss
    GROUP BY ss.ss_store_sk
),
warehouse_profit AS (
    SELECT 
        w.w_warehouse_sk,
        SUM(ws.ws_net_profit) AS total_net_profit
    FROM warehouse w
    LEFT JOIN web_sales ws ON w.w_warehouse_sk = ws.ws_warehouse_sk
    GROUP BY w.w_warehouse_sk
)
SELECT 
    hvc.c_customer_id,
    hvc.cd_gender,
    hvc.avg_spent,
    sss.total_store_profit,
    wp.total_net_profit,
    CASE 
        WHEN hvc.avg_spent IS NULL THEN 'No Purchases Yet'
        WHEN hvc.avg_spent > 100 THEN 'High Roller'
        ELSE 'Casual Shopper'
    END AS customer_classification,
    CASE 
        WHEN wp.total_net_profit IS NULL THEN 'No Profit Yet'
        ELSE 'Profitable Warehouse'
    END AS warehouse_status
FROM high_value_customers hvc
CROSS JOIN store_sales_summary sss
CROSS JOIN warehouse_profit wp
WHERE hvc.demographic_zip IS NOT NULL
  AND hvc.avg_spent IS NOT NULL
ORDER BY hvc.avg_spent DESC
LIMIT 100;
