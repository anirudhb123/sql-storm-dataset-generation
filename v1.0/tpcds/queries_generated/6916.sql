
WITH sales_summary AS (
    SELECT
        ws.web_site_id,
        d.d_year,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        AVG(ws.ws_net_profit) AS average_profit
    FROM
        web_sales ws
    JOIN
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN
        web_site w ON ws.ws_web_site_sk = w.web_site_sk
    WHERE
        d.d_year BETWEEN 2020 AND 2023
    GROUP BY
        ws.web_site_id,
        d.d_year
),
customer_summary AS (
    SELECT
        c.c_customer_id,
        cd.cd_gender,
        SUM(ws.ws_ext_sales_price) AS total_spent,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM
        customer c
    JOIN
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY
        c.c_customer_id,
        cd.cd_gender
),
warehouse_summary AS (
    SELECT
        w.w_warehouse_id,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_ext_sales_price) AS warehouse_sales
    FROM
        warehouse w
    JOIN
        web_sales ws ON ws.ws_warehouse_sk = w.w_warehouse_sk
    GROUP BY
        w.w_warehouse_id
)
SELECT
    ss.web_site_id,
    ss.d_year,
    ss.total_quantity,
    ss.total_sales,
    cs.total_spent,
    cs.order_count,
    ws.w_warehouse_id,
    ws.total_orders,
    ws.warehouse_sales
FROM
    sales_summary ss
JOIN
    customer_summary cs ON ss.web_site_id = (SELECT web_site_id FROM web_site LIMIT 1) -- Assuming we are interested in the first website
JOIN
    warehouse_summary ws ON ws.total_orders > 0
ORDER BY
    ss.d_year,
    ss.total_sales DESC;
