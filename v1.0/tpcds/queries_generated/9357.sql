
WITH sales_data AS (
    SELECT
        ws.web_site_id,
        SUM(ws.ws_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_quantity) AS total_quantity,
        AVG(ws.ws_net_profit) AS average_profit
    FROM web_sales ws
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE dd.d_year = 2023
    AND cd.cd_gender = 'F'
    AND cd.cd_marital_status = 'M'
    GROUP BY ws.web_site_id
),
warehouse_data AS (
    SELECT
        w.w_warehouse_id,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders_from_warehouse
    FROM warehouse w
    JOIN inventory i ON w.w_warehouse_sk = i.inv_warehouse_sk
    JOIN web_sales ws ON i.inv_item_sk = ws.ws_item_sk
    WHERE ws.ws_sold_date_sk = (
        SELECT MAX(ws2.ws_sold_date_sk)
        FROM web_sales ws2
    )
    GROUP BY w.w_warehouse_id
)
SELECT 
    sd.web_site_id,
    sd.total_sales,
    sd.total_orders,
    sd.total_quantity,
    sd.average_profit,
    wd.total_orders_from_warehouse
FROM sales_data sd
LEFT JOIN warehouse_data wd ON sd.web_site_id = wd.w.warehouse_id
ORDER BY sd.total_sales DESC
LIMIT 10;
