
WITH sales_summary AS (
    SELECT
        w.w_warehouse_name,
        s.s_store_name,
        d.d_year,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_sales_price * ws.ws_quantity) AS total_sales,
        AVG(ws.ws_sales_price) AS avg_sales_price,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM
        web_sales ws
    JOIN
        warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN
        store s ON ws.ws_ship_addr_sk = s.s_addr_sk
    JOIN
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE
        d.d_year = 2023
    GROUP BY
        w.w_warehouse_name,
        s.s_store_name,
        d.d_year
),
customer_summary AS (
    SELECT
        cd.cd_gender,
        cd.cd_marital_status,
        COUNT(DISTINCT c.c_customer_sk) AS num_customers,
        AVG(cd.cd_purchase_estimate) AS avg_purchase_estimate
    FROM
        customer c
    JOIN
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY
        cd.cd_gender,
        cd.cd_marital_status
)
SELECT
    ss.w_warehouse_name,
    ss.s_store_name,
    ss.total_quantity,
    ss.total_sales,
    ss.avg_sales_price,
    cs.num_customers,
    cs.avg_purchase_estimate
FROM
    sales_summary ss
JOIN
    customer_summary cs ON cs.num_customers > 0
ORDER BY
    ss.total_sales DESC, cs.avg_purchase_estimate DESC
LIMIT 100;
