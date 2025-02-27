
WITH CustomerStats AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_net_paid) AS total_spent,
        AVG(ws.ws_net_profit) AS avg_profit_per_order,
        NTILE(4) OVER (PARTITION BY cd.cd_gender ORDER BY SUM(ws.ws_net_paid) DESC) AS spending_quartile
    FROM
        customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE
        c.c_birth_year BETWEEN 1980 AND 1995
    GROUP BY
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status
),
TopProducts AS (
    SELECT
        i.i_item_id,
        i.i_product_name,
        SUM(ws.ws_quantity) AS total_quantity_sold,
        SUM(ws.ws_net_sales) AS total_sales,
        ROW_NUMBER() OVER (ORDER BY SUM(ws.ws_quantity) DESC) AS rank
    FROM
        item i
    JOIN web_sales ws ON i.i_item_sk = ws.ws_item_sk
    GROUP BY
        i.i_item_id, i.i_product_name
),
ReturnedOrders AS (
    SELECT
        sr.sr_customer_sk,
        COUNT(*) AS total_returns,
        SUM(sr.sr_return_amt_inc_tax) AS total_returned_amount
    FROM
        store_returns sr
    GROUP BY
        sr.sr_customer_sk
)
SELECT
    cs.c_first_name,
    cs.c_last_name,
    cs.cd_gender,
    cs.total_orders,
    cs.total_spent,
    cs.avg_profit_per_order,
    tp.i_product_name,
    tp.total_quantity_sold,
    ro.total_returns,
    COALESCE(ro.total_returned_amount, 0) AS total_returned_amount
FROM
    CustomerStats cs
LEFT JOIN TopProducts tp ON cs.total_orders > 10
LEFT JOIN ReturnedOrders ro ON cs.c_customer_sk = ro.sr_customer_sk
WHERE
    cs.spending_quartile = 1 OR cs.spending_quartile = 2
ORDER BY
    cs.total_spent DESC, tp.total_quantity_sold DESC;
