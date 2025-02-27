
WITH RECURSIVE top_selling_items AS (
    SELECT
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        ROW_NUMBER() OVER (ORDER BY SUM(ws_quantity) DESC) AS rank
    FROM
        web_sales
    GROUP BY
        ws_item_sk
    HAVING
        SUM(ws_quantity) > 100
),
sales_summary AS (
    SELECT
        ca_state,
        COUNT(DISTINCT c_customer_sk) AS customer_count,
        SUM(ws_net_profit) AS total_net_profit,
        AVG(ws_net_paid) AS avg_net_paid,
        MAX(ws_net_paid) AS max_net_paid,
        MIN(ws_net_paid) AS min_net_paid
    FROM
        web_sales ws
    JOIN
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    WHERE
        ws_sold_date_sk BETWEEN (
            SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023
        ) AND (
            SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023
        )
    GROUP BY
        ca_state
),
refunds AS (
    SELECT
        'web' AS source,
        SUM(wr_return_amt) AS total_refund
    FROM
        web_returns
    WHERE
        wr_returned_date_sk BETWEEN (
            SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023
        ) AND (
            SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023
        )
    UNION ALL
    SELECT
        'store' AS source,
        SUM(sr_return_amt) AS total_refund
    FROM
        store_returns
    WHERE
        sr_returned_date_sk BETWEEN (
            SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023
        ) AND (
            SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023
        )
)
SELECT
    ss.ca_state,
    ss.customer_count,
    ss.total_net_profit,
    ss.avg_net_paid,
    ss.max_net_paid,
    ss.min_net_paid,
    COALESCE(r.total_refund, 0) AS total_refund,
    ti.ws_item_sk AS item_desc,
    ti.total_quantity
FROM
    sales_summary ss
LEFT JOIN
    refunds r ON 1=1
JOIN
    top_selling_items ti ON ss.ca_state = (
        SELECT
            ca_state
        FROM
            customer_address
        WHERE
            ca_address_sk = (
                SELECT
                    c.c_current_addr_sk
                FROM
                    customer c
                WHERE
                    c.c_customer_sk = ti.ws_item_sk
                LIMIT 1
            )
        LIMIT 1
    )
ORDER BY
    ss.total_net_profit DESC
LIMIT 10;
