
WITH RECURSIVE date_hierarchy AS (
    SELECT d_date_sk, d_date, d_year, d_month_seq, d_week_seq, 1 AS level
    FROM date_dim
    WHERE d_year = 2021 AND d_month_seq = 1
    UNION ALL
    SELECT dd.d_date_sk, dd.d_date, dd.d_year, dd.d_month_seq, dd.d_week_seq, dh.level + 1
    FROM date_hierarchy dh
    JOIN date_dim dd ON dd.d_year = 2021 AND dd.d_month_seq = dh.d_month_seq + 1
    WHERE dd.d_month_seq <= 12 AND dd.d_date > dh.d_date
),
customer_stats AS (
    SELECT 
        c.c_customer_id,
        cd.cd_gender,
        COUNT(DISTINCT ss_ticket_number) AS total_sales,
        SUM(ss_net_paid) AS total_spent,
        SUM(ss_net_profit) AS total_profit,
        DENSE_RANK() OVER (PARTITION BY cd.cd_gender ORDER BY SUM(ss_net_paid) DESC) AS rank
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    JOIN date_hierarchy dh ON ss.ss_sold_date_sk = dh.d_date_sk
    GROUP BY c.c_customer_id, cd.cd_gender
),
top_customers AS (
    SELECT c.c_customer_id, c.cd_gender, c.total_sales, c.total_spent, c.total_profit
    FROM customer_stats c
    WHERE c.rank <= 10
),
geo_locations AS (
    SELECT 
        w.w_warehouse_id, 
        w.w_state,
        COUNT(DISTINCT inv.inv_item_sk) AS total_items_available
    FROM warehouse w
    JOIN inventory inv ON w.w_warehouse_sk = inv.inv_warehouse_sk
    GROUP BY w.w_warehouse_id, w.w_state
)
SELECT 
    tc.c_customer_id,
    tc.cd_gender,
    tc.total_sales,
    tc.total_spent,
    tc.total_profit,
    gl.w_warehouse_id,
    gl.w_state,
    gl.total_items_available,
    COALESCE(sm.sm_type, 'N/A') AS shipping_method
FROM top_customers tc
LEFT JOIN geo_locations gl ON (tc.total_sales > 0)
LEFT JOIN ship_mode sm ON tc.total_spent > 100
ORDER BY tc.total_spent DESC, gl.total_items_available DESC;
