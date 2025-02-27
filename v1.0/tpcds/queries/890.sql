
WITH CustomerStats AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        SUM(ws.ws_quantity) AS total_purchases,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        AVG(ws.ws_net_paid_inc_tax) AS avg_spent,
        SUM(ws.ws_net_paid_inc_tax) / NULLIF(COUNT(DISTINCT ws.ws_order_number), 0) AS avg_per_order
    FROM
        customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status
),
TopCustomers AS (
    SELECT
        *,
        DENSE_RANK() OVER (PARTITION BY cd_gender ORDER BY total_purchases DESC) AS rank
    FROM
        CustomerStats
)
SELECT
    tc.c_customer_sk,
    tc.c_first_name,
    tc.c_last_name,
    tc.total_purchases,
    tc.order_count,
    tc.avg_spent,
    NULLIF(tc.avg_per_order, 0) AS avg_per_order,
    CASE
        WHEN tc.cd_marital_status = 'M' THEN 'Married'
        ELSE 'Single'
    END AS marital_status_desc,
    wm.w_warehouse_name
FROM
    TopCustomers tc
LEFT JOIN warehouse wm ON (wm.w_warehouse_sk = (
    SELECT inv.inv_warehouse_sk
    FROM inventory inv
    WHERE inv.inv_item_sk IN (
        SELECT ws.ws_item_sk
        FROM web_sales ws
        WHERE ws.ws_bill_customer_sk = tc.c_customer_sk
    )
    GROUP BY inv.inv_warehouse_sk
    ORDER BY SUM(inv.inv_quantity_on_hand) DESC 
    LIMIT 1
))
WHERE
    tc.rank <= 10
ORDER BY
    tc.cd_gender,
    tc.total_purchases DESC;
