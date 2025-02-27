
WITH CTE_CustomerSales AS (
    SELECT
        c.c_customer_id,
        SUM(ws.ws_net_paid) AS total_sales,
        COUNT(ws.ws_order_number) AS total_orders,
        AVG(ws.ws_net_paid) AS avg_order_value
    FROM
        customer c
    JOIN
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE
        ws.ws_sold_date_sk BETWEEN 1 AND 365 -- sales within the first year
    GROUP BY
        c.c_customer_id
),
CTE_ItemSales AS (
    SELECT
        ws.ws_item_sk,
        COUNT(ws.ws_order_number) AS total_orders,
        SUM(ws.ws_net_paid) AS net_sales,
        AVG(ws.ws_net_paid) AS avg_order_value
    FROM
        web_sales ws
    GROUP BY
        ws.ws_item_sk
),
CTE_Returns AS (
    SELECT
        cr.cr_item_sk,
        SUM(cr.cr_return_amount) AS total_returned_amount,
        COUNT(cr.cr_order_number) AS total_returns
    FROM
        catalog_returns cr
    GROUP BY
        cr.cr_item_sk
),
CTE_ShipModes AS (
    SELECT
        sm.sm_ship_mode_id,
        AVG(ws.ws_net_paid) AS avg_net_paid
    FROM
        ship_mode sm
    JOIN
        web_sales ws ON sm.sm_ship_mode_sk = ws.ws_ship_mode_sk
    GROUP BY
        sm.sm_ship_mode_id
)

SELECT
    c.customer_id,
    cs.total_sales,
    cs.total_orders,
    cs.avg_order_value,
    COALESCE(is.total_orders, 0) AS item_total_orders,
    COALESCE(is.net_sales, 0) AS item_net_sales,
    SM.sm_ship_mode_id,
    AVG(SM.avg_net_paid) AS avg_ship_mode_net_paid,
    COALESCE(r.total_returned_amount, 0) AS total_returned_amount,
    COALESCE(r.total_returns, 0) AS total_returns,
    CASE
        WHEN cs.total_sales > 1000 THEN 'High Value'
        WHEN cs.total_sales BETWEEN 500 AND 1000 THEN 'Mid Value'
        ELSE 'Low Value'
    END AS customer_value_category
FROM
    CTE_CustomerSales cs
LEFT JOIN
    CTE_ItemSales is ON cs.c_customer_id = is.ws_item_sk
LEFT JOIN
    CTE_Returns r ON is.ws_item_sk = r.cr_item_sk
LEFT JOIN
    CTE_ShipModes SM ON SM.sm_ship_mode_id = (
        SELECT sm.sm_ship_mode_id
        FROM ship_mode sm
        ORDER BY RANDOM()
        LIMIT 1 -- Randomly selecting one ship mode for demonstration purposes
    )
JOIN
    customer c ON c.c_customer_id = cs.c_customer_id
WHERE
    cs.total_orders > 2
ORDER BY
    cs.total_sales DESC
LIMIT 100;
