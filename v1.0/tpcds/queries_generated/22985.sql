
WITH customer_summary AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS rnk
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
top_customers AS (
    SELECT 
        cs.c_customer_sk,
        cs.c_first_name,
        cs.c_last_name,
        cs.cd_gender,
        cs.cd_marital_status,
        cs.cd_purchase_estimate
    FROM customer_summary cs
    WHERE cs.rnk <= 10
),
store_info AS (
    SELECT 
        s.s_store_sk,
        s.s_store_id,
        s.s_store_name,
        MAX(ss.ss_net_sales) AS max_sales
    FROM store s
    JOIN (
        SELECT 
            ss_store_sk,
            SUM(ss_net_paid) AS ss_net_sales
        FROM store_sales
        GROUP BY ss_store_sk
    ) ss ON s.s_store_sk = ss.ss_store_sk
    GROUP BY s.s_store_sk, s.s_store_id, s.s_store_name
),
warehouse_summary AS (
    SELECT 
        w.w_warehouse_sk,
        w.w_warehouse_name,
        COUNT(DISTINCT inv.inv_item_sk) AS item_count,
        SUM(inv.inv_quantity_on_hand) AS total_quantity
    FROM warehouse w
    JOIN inventory inv ON w.w_warehouse_sk = inv.inv_warehouse_sk
    GROUP BY w.w_warehouse_sk, w.w_warehouse_name
),
top_stores AS (
    SELECT 
        si.s_store_name,
        si.max_sales
    FROM store_info si
    WHERE si.max_sales > (SELECT AVG(max_sales) FROM store_info)
),
customer_store_info AS (
    SELECT
        tc.c_customer_sk,
        ts.s_store_name,
        SUM(ws.ws_net_paid) AS total_spent,
        COUNT(ws.ws_order_number) AS total_orders
    FROM top_customers tc
    JOIN web_sales ws ON tc.c_customer_sk = ws.ws_bill_customer_sk
    JOIN top_stores ts ON ws.ws_warehouse_sk = ts.s_store_sk
    GROUP BY tc.c_customer_sk, ts.s_store_name
)
SELECT 
    csi.c_customer_sk,
    csi.s_store_name,
    csi.total_spent,
    csi.total_orders,
    CASE 
        WHEN csi.total_spent IS NULL THEN 'No Purchases'
        WHEN csi.total_orders = 0 THEN 'No Orders'
        ELSE CAST(csi.total_spent / NULLIF(csi.total_orders, 0) AS DECIMAL(10,2))
    END AS avg_spent_per_order
FROM customer_store_info csi
WHERE EXISTS (
    SELECT 1
    FROM store s 
    WHERE s.s_store_name LIKE 'Super%' AND csi.s_store_name = s.s_store_name
)
ORDER BY avg_spent_per_order DESC NULLS LAST;
