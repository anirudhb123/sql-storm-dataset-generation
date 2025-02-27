
WITH SalesSummary AS (
    SELECT
        ws_item_sk,
        COUNT(ws_order_number) AS total_orders,
        SUM(ws_ext_sales_price) AS total_sales,
        AVG(ws_net_profit) AS avg_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_ext_sales_price) DESC) AS sales_rank
    FROM
        web_sales
    WHERE
        ws_sold_date_sk BETWEEN (SELECT d_date_sk FROM date_dim WHERE d_date = CURRENT_DATE - INTERVAL '30 days')
        AND (SELECT d_date_sk FROM date_dim WHERE d_date = CURRENT_DATE)
    GROUP BY
        ws_item_sk
),
TopItems AS (
    SELECT
        s.ws_item_sk,
        s.total_orders,
        s.total_sales,
        s.avg_net_profit,
        i.i_item_desc,
        i.i_current_price,
        sm.sm_type,
        ROW_NUMBER() OVER (ORDER BY s.total_sales DESC) AS item_rank
    FROM
        SalesSummary s
    JOIN
        item i ON s.ws_item_sk = i.i_item_sk
    LEFT JOIN
        ship_mode sm ON EXISTS (SELECT 1 FROM web_sales ws WHERE ws.ws_item_sk = i.i_item_sk AND ws.sm_ship_mode_sk = sm.sm_ship_mode_sk)
    WHERE
        s.sales_rank <= 10
),
CustomerSummary AS (
    SELECT
        c.c_customer_sk,
        COUNT(ws.ws_order_number) AS total_orders,
        SUM(ws.ws_ext_sales_price) AS total_spent,
        MAX(ws.ws_sold_date_sk) AS last_purchase_date
    FROM
        customer c
    JOIN
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY
        c.c_customer_sk
)
SELECT
    ti.i_item_desc,
    ti.total_orders,
    ti.total_sales,
    ti.avg_net_profit,
    ti.i_current_price,
    cs.total_orders AS customer_orders,
    cs.total_spent,
    cs.last_purchase_date
FROM
    TopItems ti
FULL OUTER JOIN
    CustomerSummary cs ON cs.total_spent > 1000  -- Let’s say we want only customers who spent more than $1000
WHERE
    ti.item_rank <= 5 OR cs.total_orders > 5  -- Filtering for top 5 items or customers with more than 5 orders
ORDER BY
    ti.total_sales DESC NULLS LAST, cs.total_spent DESC NULLS LAST;
