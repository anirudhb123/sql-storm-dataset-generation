
WITH sales_summary AS (
    SELECT
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity_sold,
        SUM(ws_net_paid) AS total_revenue,
        COUNT(DISTINCT ws_order_number) AS total_orders
    FROM
        web_sales
    WHERE
        ws_sold_date_sk BETWEEN 2458587 AND 2458597 -- Example date range
    GROUP BY
        ws_item_sk
),
top_items AS (
    SELECT
        ss_item_sk,
        total_quantity_sold,
        total_revenue,
        total_orders,
        RANK() OVER (ORDER BY total_revenue DESC) AS revenue_rank,
        RANK() OVER (ORDER BY total_quantity_sold DESC) AS quantity_rank
    FROM
        sales_summary
),
customer_summary AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        COUNT(DISTINCT ws_order_number) AS total_orders,
        SUM(ws_net_paid) AS total_spent
    FROM
        customer c
    JOIN
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status
)
SELECT
    t.c_first_name,
    t.c_last_name,
    t.total_orders,
    t.total_spent,
    ti.total_quantity_sold,
    ti.total_revenue
FROM
    customer_summary t
JOIN
    top_items ti ON ti.ss_item_sk IN (
        SELECT ws_item_sk 
        FROM web_sales 
        WHERE ws_net_paid > 100 -- Filtering to get the items sold for more than 100
    )
WHERE
    t.total_orders > 5 -- Include only customers with more than 5 orders
ORDER BY
    ti.total_revenue DESC, t.total_spent DESC
LIMIT 10;
