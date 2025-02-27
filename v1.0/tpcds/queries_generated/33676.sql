
WITH RECURSIVE sales_summary AS (
    SELECT
        ws.bill_customer_sk,
        SUM(ws.ext_sales_price) AS total_sales,
        COUNT(ws.order_number) AS order_count,
        ROW_NUMBER() OVER (PARTITION BY ws.bill_customer_sk ORDER BY SUM(ws.ext_sales_price) DESC) AS rank
    FROM web_sales ws
    WHERE ws.sold_date_sk >= (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY ws.bill_customer_sk
    HAVING SUM(ws.ext_sales_price) > 10000
),
high_value_customers AS (
    SELECT
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        ss.total_sales,
        ss.order_count
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN sales_summary ss ON c.c_customer_sk = ss.bill_customer_sk
    WHERE cd.cd_purchase_estimate IS NOT NULL
),
warehouse_info AS (
    SELECT 
        w.w_warehouse_nf,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_ext_sales_price) AS total_sales
    FROM warehouse w
    LEFT JOIN web_sales ws ON w.w_warehouse_sk = ws.ws_warehouse_sk
    GROUP BY w.w_warehouse_sk
),
top_warehouses AS (
    SELECT 
        w.w_warehouse_id,
        wi.total_orders,
        wi.total_sales,
        ROW_NUMBER() OVER (ORDER BY wi.total_sales DESC) AS warehouse_rank
    FROM warehouse w
    JOIN warehouse_info wi ON w.w_warehouse_sk = wi.w_warehouse_sk
    WHERE wi.total_orders > 50
)
SELECT
    hvc.c_customer_id,
    hvc.cd_gender,
    hvc.cd_marital_status,
    hvc.cd_purchase_estimate,
    tw.warehouse_id,
    tw.total_orders,
    tw.total_sales
FROM high_value_customers hvc
JOIN top_warehouses tw ON hvc.total_sales > (SELECT AVG(total_sales) FROM high_value_customers)
WHERE hvc.order_count > 10
ORDER BY tw.total_sales DESC, hvc.total_sales DESC;
