
WITH sales_summary AS (
    SELECT 
        ws_item_sk,
        COUNT(ws_order_number) AS total_orders,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_paid_inc_tax) AS total_revenue,
        AVG(ws_sales_price) AS avg_sales_price
    FROM web_sales
    JOIN item ON ws_item_sk = i_item_sk
    WHERE ws_sold_date_sk BETWEEN 2450000 AND 2450600
    GROUP BY ws_item_sk
),
customer_analysis AS (
    SELECT 
        c_current_cdemo_sk,
        COUNT(DISTINCT c_customer_id) AS customer_count,
        SUM(cd_dep_count) AS total_dependents,
        AVG(cd_purchase_estimate) AS avg_purchase_estimate
    FROM customer 
    JOIN customer_demographics ON c_current_cdemo_sk = cd_demo_sk
    GROUP BY c_current_cdemo_sk
),
warehouse_performance AS (
    SELECT 
        w_warehouse_sk,
        SUM(CASE WHEN ws_item_sk IS NOT NULL THEN 1 ELSE 0 END) AS sold_item_count,
        AVG(ws_sales_price) AS avg_sale_price,
        SUM(ws_net_paid_inc_tax) AS total_revenue
    FROM warehouse
    LEFT JOIN web_sales ON w_warehouse_sk = ws_warehouse_sk
    GROUP BY w_warehouse_sk
)
SELECT 
    ss.ws_item_sk,
    ss.total_orders,
    ss.total_quantity,
    ss.total_revenue,
    ss.avg_sales_price,
    ca.customer_count,
    ca.total_dependents,
    ca.avg_purchase_estimate,
    wp.warehouse_sk,
    wp.sold_item_count,
    wp.avg_sale_price,
    wp.total_revenue 
FROM sales_summary ss
JOIN customer_analysis ca ON ss.ws_item_sk = ca.c_current_cdemo_sk
JOIN warehouse_performance wp ON ss.ws_item_sk = wp.sold_item_count
ORDER BY ss.total_revenue DESC
LIMIT 100;
