
WITH sales_summary AS (
    SELECT 
        ws.web_site_sk,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        AVG(ws.ws_net_profit) AS average_profit,
        DATE_FORMAT(d.d_date, '%Y-%m') AS sales_month
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    WHERE d.d_year = 2023
      AND cd.cd_gender = 'F'
      AND i.i_current_price > 20.00
    GROUP BY ws.web_site_sk, sales_month
),
warehouse_summary AS (
    SELECT 
        w.w_warehouse_sk,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_ext_ship_cost) AS total_ship_cost,
        AVG(ws.ws_net_paid) AS average_net_paid
    FROM warehouse w
    JOIN web_sales ws ON w.w_warehouse_sk = ws.ws_warehouse_sk
    GROUP BY w.w_warehouse_sk
),
final_summary AS (
    SELECT
        s.sales_month,
        ss.web_site_sk,
        w.w_warehouse_sk,
        ss.total_sales,
        ss.order_count,
        ws.total_orders,
        ws.total_ship_cost,
        ws.average_net_paid
    FROM sales_summary ss
    JOIN warehouse_summary ws ON ss.web_site_sk = ws.w_warehouse_sk
    JOIN date_dim d ON d.d_year = 2023
    WHERE ss.sales_month = DATE_FORMAT(d.d_date, '%Y-%m')
)
SELECT 
    sales_month,
    web_site_sk,
    w_warehouse_sk,
    total_sales,
    order_count,
    total_orders,
    total_ship_cost,
    average_net_paid
FROM final_summary
ORDER BY sales_month, web_site_sk, w_warehouse_sk;
