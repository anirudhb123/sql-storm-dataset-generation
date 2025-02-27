
WITH CustomerStatistics AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        SUM(ws.ws_net_paid) AS total_spent,
        COUNT(ws.ws_order_number) AS total_orders
    FROM
        customer c
    JOIN
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status, cd.cd_education_status
),
SalesByDate AS (
    SELECT
        d.d_date,
        SUM(ws.ws_net_paid) AS total_sales,
        COUNT(ws.ws_order_number) AS total_orders
    FROM
        date_dim d
    LEFT JOIN
        web_sales ws ON d.d_date_sk = ws.ws_sold_date_sk
    WHERE
        d.d_year = 2023
    GROUP BY
        d.d_date
),
TopProducts AS (
    SELECT
        i.i_item_sk,
        i.i_product_name,
        SUM(ws.ws_quantity) AS total_units_sold,
        SUM(ws.ws_net_paid) AS total_revenue
    FROM
        item i
    JOIN
        web_sales ws ON i.i_item_sk = ws.ws_item_sk
    GROUP BY
        i.i_item_sk, i.i_product_name
    ORDER BY
        total_revenue DESC
    LIMIT 10
)
SELECT
    cs.c_first_name,
    cs.c_last_name,
    cs.total_spent,
    cs.total_orders,
    sbd.total_sales,
    sbd.total_orders AS daily_total_orders,
    tp.i_product_name,
    tp.total_units_sold,
    tp.total_revenue
FROM
    CustomerStatistics cs
JOIN
    SalesByDate sbd ON cs.total_orders > 0
CROSS JOIN
    TopProducts tp
ORDER BY
    cs.total_spent DESC, tp.total_revenue DESC;
