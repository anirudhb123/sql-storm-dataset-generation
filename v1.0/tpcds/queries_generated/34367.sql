
WITH RECURSIVE sales_analysis AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_net_profit) AS total_profit,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        SUM(ws.ws_quantity) AS total_quantity,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY SUM(ws.ws_net_profit) DESC) AS rank
    FROM
        customer c
    JOIN
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY
        c.c_customer_sk, c.c_first_name, c.c_last_name
    HAVING
        SUM(ws.ws_net_profit) > 1000
),
top_customers AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        sa.total_profit,
        sa.order_count
    FROM
        sales_analysis sa
    JOIN
        customer c ON sa.c_customer_sk = c.c_customer_sk
    WHERE
        sa.rank <= 10
),
inventory_summary AS (
    SELECT
        i.i_item_sk,
        SUM(inv.inv_quantity_on_hand) AS total_inventory
    FROM
        item i
    JOIN
        inventory inv ON i.i_item_sk = inv.inv_item_sk
    GROUP BY
        i.i_item_sk
),
sales_details AS (
    SELECT
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_sold,
        SUM(ws.ws_sales_price) AS total_sales,
        COALESCE(SUM(sr.sr_return_quantity), 0) AS total_returns,
        (SUM(ws.ws_quantity) - COALESCE(SUM(sr.sr_return_quantity), 0)) AS net_sales
    FROM
        web_sales ws
    LEFT JOIN
        store_returns sr ON ws.ws_item_sk = sr.sr_item_sk
    GROUP BY
        ws.ws_item_sk
)
SELECT
    tc.c_first_name,
    tc.c_last_name,
    ds.ws_item_sk,
    i.i_item_desc,
    ds.total_sold,
    ds.total_sales,
    ds.total_returns,
    ds.net_sales,
    (ds.total_sales / NULLIF(i.total_inventory, 0)) * 100 AS sales_efficiency
FROM
    top_customers tc
JOIN
    sales_details ds ON tc.c_customer_sk = ds.ws_item_sk
JOIN
    inventory_summary i ON ds.ws_item_sk = i.i_item_sk
WHERE
    ds.net_sales > 0
ORDER BY
    sales_efficiency DESC;
