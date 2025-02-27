
WITH RECURSIVE date_hierarchy AS (
    SELECT d_date_sk, d_date, d_year, d_month_seq, d_week_seq, d_day_name
    FROM date_dim
    WHERE d_year = 2023
    UNION ALL
    SELECT d_next.d_date_sk, d_next.d_date, d_next.d_year, d_next.d_month_seq, d_next.d_week_seq, d_next.d_day_name
    FROM date_dim d_next
    JOIN date_hierarchy dh ON d_next.d_date_sk = dh.d_date_sk + 1
),
customer_stats AS (
    SELECT 
        c.c_customer_sk, 
        c.c_first_name, 
        c.c_last_name,
        MAX(cd.cd_purchase_estimate) AS max_purchase_estimate,
        AVG(cd.cd_dep_count) AS avg_dep_count,
        COUNT(DISTINCT ws.ws_order_number) AS web_orders_count,
        SUM(ws.ws_net_profit) AS total_web_profit
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE cd.cd_gender = 'F' 
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name
),
warehouse_stats AS (
    SELECT 
        w.w_warehouse_sk,
        SUM(inv.inv_quantity_on_hand) AS total_quantity_on_hand,
        COUNT(DISTINCT cs.cs_order_number) AS total_catalog_sales
    FROM warehouse w
    LEFT JOIN inventory inv ON w.w_warehouse_sk = inv.inv_warehouse_sk
    LEFT JOIN catalog_sales cs ON w.w_warehouse_sk = cs.cs_warehouse_sk
    GROUP BY w.w_warehouse_sk
),
detailed_sales AS (
    SELECT 
        ws.ws_sold_date_sk,
        ws.ws_item_sk,
        SUM(ws.ws_sales_price) AS total_sales_price,
        SUM(CASE WHEN ws.ws_ship_mode_sk IS NULL THEN 1 ELSE 0 END) AS free_ship_count,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM web_sales ws
    GROUP BY ws.ws_sold_date_sk, ws.ws_item_sk
)
SELECT 
    dh.d_year,
    dh.d_week_seq,
    cs.c_first_name,
    cs.c_last_name,
    cs.max_purchase_estimate,
    ws.total_quantity_on_hand,
    ds.total_sales_price,
    ds.free_ship_count,
    ds.order_count
FROM date_hierarchy dh
JOIN customer_stats cs ON cs.max_purchase_estimate IS NOT NULL
LEFT JOIN warehouse_stats ws ON ws.total_quantity_on_hand IS NOT NULL
LEFT JOIN detailed_sales ds ON ds.ws_sold_date_sk = dh.d_date_sk
WHERE (ws.total_catalog_sales > 200 OR ds.order_count > 10)
ORDER BY dh.d_year, dh.d_week_seq, cs.c_last_name, cs.c_first_name;
