
WITH RECURSIVE sales_trends AS (
    SELECT
        d.d_year,
        SUM(ws.net_profit) AS total_net_profit,
        SUM(ws.ws_quantity) AS total_quantity_sold
    FROM
        date_dim d
    JOIN web_sales ws ON d.d_date_sk = ws.ws_sold_date_sk
    WHERE
        d.d_year BETWEEN 2020 AND 2023
    GROUP BY
        d.d_year
    UNION ALL
    SELECT
        d.d_year,
        SUM(ws.net_profit) AS total_net_profit,
        SUM(ws.ws_quantity) AS total_quantity_sold
    FROM
        date_dim d
    JOIN web_sales ws ON d.d_date_sk = ws.ws_sold_date_sk
    JOIN sales_trends st ON st.d_year + 1 = d.d_year
    GROUP BY
        d.d_year
),
customer_summary AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        COALESCE(cd.cd_purchase_estimate, 0) AS purchase_estimate,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_net_profit) AS total_spent
    FROM
        customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    GROUP BY
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_purchase_estimate
),
top_customers AS (
    SELECT
        cs.c_customer_sk,
        cs.c_first_name,
        cs.c_last_name,
        cs.total_orders,
        cs.total_spent,
        RANK() OVER (ORDER BY cs.total_spent DESC) AS rank
    FROM
        customer_summary cs
),
warehouse_summary AS (
    SELECT
        w.w_warehouse_sk,
        w.w_warehouse_name,
        SUM(ws.ws_quantity) AS total_quantity_sold
    FROM
        warehouse w
    JOIN web_sales ws ON w.w_warehouse_sk = ws.ws_warehouse_sk
    GROUP BY
        w.w_warehouse_sk, w.w_warehouse_name
)
SELECT
    tc.c_first_name,
    tc.c_last_name,
    tc.total_spent,
    w.w_warehouse_name,
    st.total_net_profit,
    st.total_quantity_sold
FROM
    top_customers tc
JOIN warehouse_summary w ON w.total_quantity_sold > 1000
JOIN sales_trends st ON st.total_net_profit > 50000
WHERE
    tc.rank <= 10
ORDER BY
    tc.total_spent DESC;
