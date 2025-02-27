
WITH revenue_summary AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_net_profit) AS total_net_profit,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM
        customer c
    JOIN
        web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    WHERE
        ws.ws_sold_date_sk BETWEEN (SELECT MAX(d.d_date_sk) FROM date_dim d WHERE d.d_year = 2023) - 30
        AND (SELECT MAX(d.d_date_sk) FROM date_dim d WHERE d.d_year = 2023)
    GROUP BY
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
top_customers AS (
    SELECT
        *,
        RANK() OVER (ORDER BY total_net_profit DESC) AS rnk
    FROM
        revenue_summary
),
inventory_summary AS (
    SELECT
        inv.inv_item_sk,
        SUM(inv.inv_quantity_on_hand) AS total_stock
    FROM
        inventory inv
    WHERE
        inv.inv_date_sk = (SELECT MAX(inv_date_sk) FROM inventory)
    GROUP BY
        inv.inv_item_sk
)
SELECT
    tc.c_customer_sk,
    tc.c_first_name,
    tc.c_last_name,
    tc.total_net_profit,
    tc.order_count,
    ISNULL(i.item_description, 'Unknown Item') AS item_description,
    ISNULL(i.current_price, 0) AS item_price,
    COALESCE(s.total_stock, 0) AS stock_available
FROM
    top_customers tc
LEFT JOIN
    item i ON i.i_item_sk = (SELECT ws.ws_item_sk FROM web_sales ws WHERE ws.ws_bill_customer_sk = tc.c_customer_sk LIMIT 1)
LEFT JOIN
    inventory_summary s ON i.i_item_sk = s.inv_item_sk
WHERE
    tc.rnk <= 10
ORDER BY
    tc.total_net_profit DESC;
