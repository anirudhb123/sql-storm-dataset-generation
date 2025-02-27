
WITH sales_summary AS (
    SELECT
        ws.ws_bill_customer_sk,
        SUM(ws.ws_net_profit) AS total_net_profit,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        COUNT(DISTINCT ws.ws_item_sk) AS unique_items_sold
    FROM
        web_sales ws
    JOIN
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE
        cd.cd_gender = 'F' AND
        cd.cd_marital_status = 'M' AND
        cd.cd_buy_potential = 'High'
    GROUP BY
        ws.ws_bill_customer_sk
),
high_value_customers AS (
    SELECT
        ss.ws_bill_customer_sk,
        ss.total_net_profit,
        ss.total_orders,
        ss.unique_items_sold,
        ROW_NUMBER() OVER (ORDER BY ss.total_net_profit DESC) AS rank
    FROM
        sales_summary ss
)
SELECT
    c.c_first_name,
    c.c_last_name,
    h.total_net_profit,
    h.total_orders,
    h.unique_items_sold
FROM
    high_value_customers h
JOIN
    customer c ON h.ws_bill_customer_sk = c.c_customer_sk
WHERE
    h.rank <= 10
ORDER BY
    h.total_net_profit DESC;
