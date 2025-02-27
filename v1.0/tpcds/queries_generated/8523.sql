
WITH sales_summary AS (
    SELECT
        w.warehouse_id,
        s.store_id,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS total_orders,
        AVG(ws_net_profit) AS avg_profit
    FROM
        web_sales ws
    JOIN
        warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN
        store s ON ws.ws_ship_addr_sk = s.s_store_sk
    JOIN
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE
        dd.d_year = 2023
    GROUP BY
        w.warehouse_id,
        s.store_id
),
customer_summary AS (
    SELECT
        c.c_customer_id,
        cd.cd_gender,
        SUM(cos.ws_net_paid) AS total_spent,
        COUNT(DISTINCT cos.ws_order_number) AS orders_count
    FROM
        customer c
    JOIN
        web_sales cos ON c.c_customer_sk = cos.ws_bill_customer_sk
    JOIN
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY
        c.c_customer_id,
        cd.cd_gender
),
comparison AS (
    SELECT
        ss.warehouse_id,
        ss.store_id,
        cs.cd_gender,
        ss.total_sales,
        cs.total_spent,
        ss.total_orders,
        cs.orders_count,
        CASE 
            WHEN ss.total_sales > cs.total_spent THEN 'Warehouse'
            ELSE 'Customer'
        END AS leading_entity
    FROM
        sales_summary ss
    JOIN
        customer_summary cs ON ss.warehouse_id = cs.c_customer_id
)
SELECT
    warehouse_id,
    store_id,
    cd_gender,
    total_sales,
    total_spent,
    total_orders,
    orders_count,
    leading_entity
FROM
    comparison
WHERE
    total_sales > 100000
ORDER BY
    total_sales DESC, total_spent DESC;
