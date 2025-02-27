
WITH sales_summary AS (
    SELECT
        i.i_item_sk,
        i.i_item_id,
        SUM(ws.ws_quantity) AS total_quantity_sold,
        SUM(ws.ws_net_profit) AS total_net_profit,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        COUNT(DISTINCT ws.ws_bill_customer_sk) AS unique_customers
    FROM
        item i
    JOIN
        web_sales ws ON i.i_item_sk = ws.ws_item_sk
    JOIN
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE
        d.d_year = 2023
    GROUP BY
        i.i_item_sk, i.i_item_id
),
top_selling_items AS (
    SELECT
        *,
        RANK() OVER (ORDER BY total_net_profit DESC) AS item_rank
    FROM
        sales_summary
)
SELECT
    t.item_rank,
    t.i_item_id,
    t.total_quantity_sold,
    t.total_net_profit,
    t.total_orders,
    t.unique_customers,
    ca.ca_city,
    ca.ca_state
FROM
    top_selling_items t
JOIN
    customer c ON c.c_customer_sk IN (
        SELECT ws.ws_bill_customer_sk
        FROM web_sales ws
        WHERE ws.ws_item_sk = t.i_item_sk
    )
JOIN
    customer_address ca ON ca.ca_address_sk = c.c_current_addr_sk
WHERE
    t.item_rank <= 10
ORDER BY
    t.item_rank;
