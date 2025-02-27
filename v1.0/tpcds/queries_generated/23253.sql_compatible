
WITH customer_stats AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        CASE 
            WHEN cd.cd_purchase_estimate IS NULL THEN 'Unknown' 
            WHEN cd.cd_purchase_estimate < 1000 THEN 'Low Spender' 
            WHEN cd.cd_purchase_estimate BETWEEN 1000 AND 5000 THEN 'Medium Spender' 
            ELSE 'High Spender' 
        END AS spender_category,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_net_profit) AS total_profit
    FROM 
        customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status, cd.cd_purchase_estimate
),
warehouse_stats AS (
    SELECT 
        w.w_warehouse_sk,
        w.w_warehouse_id,
        SUM(ws.ws_net_profit) AS warehouse_profit,
        COUNT(DISTINCT ws.ws_order_number) AS warehouse_orders
    FROM 
        warehouse w
    LEFT JOIN web_sales ws ON w.w_warehouse_sk = ws.ws_warehouse_sk
    GROUP BY 
        w.w_warehouse_sk, w.w_warehouse_id
),
top_customers AS (
    SELECT 
        cs.c_customer_sk,
        cs.c_first_name, 
        cs.c_last_name, 
        cs.spender_category,
        RANK() OVER (PARTITION BY cs.spender_category ORDER BY cs.total_profit DESC) AS rank_within_category
    FROM 
        customer_stats cs
    WHERE 
        cs.total_orders > 0
)
SELECT 
    t.c_first_name,
    t.c_last_name,
    t.spender_category,
    w.w_warehouse_id,
    w.warehouse_profit,
    CASE 
        WHEN w.warehouse_profit > 10000 THEN 'Profitable Warehouse' 
        WHEN w.warehouse_profit IS NULL THEN 'No Sales' 
        ELSE 'Moderate Warehouse' 
    END AS warehouse_performance,
    COALESCE(tc.rank_within_category, 'N/A') AS customer_rank
FROM 
    warehouse_stats w
LEFT JOIN 
    top_customers t ON w.warehouse_orders = t.total_orders
FULL OUTER JOIN 
    (SELECT * FROM top_customers WHERE rank_within_category = 1) tc ON t.c_customer_sk = tc.c_customer_sk
WHERE 
    w.warehouse_profit IS NOT NULL AND
    (t.spender_category = 'High Spender' OR w.warehouse_profit > 5000)
ORDER BY 
    w.warehouse_profit DESC, 
    t.c_last_name ASC, 
    t.rank_within_category DESC;
