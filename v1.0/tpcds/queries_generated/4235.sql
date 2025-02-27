
WITH sales_data AS (
    SELECT
        ws.ws_order_number,
        ws.ws_net_paid_inc_tax,
        ws.ws_net_profit,
        i.i_item_desc,
        sm.sm_type,
        DATE(d.d_date) AS sales_date
    FROM
        web_sales ws
    JOIN
        item i ON ws.ws_item_sk = i.i_item_sk
    JOIN
        ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE
        d.d_year = 2023
        AND sm.sm_type IS NOT NULL
        AND ws.ws_net_paid_inc_tax > 0
),
customer_summary AS (
    SELECT
        c.c_customer_sk,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        SUM(ws.ws_net_profit) AS total_profit,
        AVG(ws.ws_net_paid_inc_tax) AS avg_order_value
    FROM
        customer c
    LEFT JOIN
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE
        c.c_current_cdemo_sk IS NOT NULL
    GROUP BY
        c.c_customer_sk
),
top_customers AS (
    SELECT
        c.c_customer_sk,
        cs.order_count,
        cs.total_profit,
        cs.avg_order_value,
        ROW_NUMBER() OVER (ORDER BY cs.total_profit DESC) AS rank
    FROM
        customer_summary cs
    JOIN
        customer c ON cs.c_customer_sk = c.c_customer_sk
    WHERE
        cs.order_count > 1
),
shipping_modes AS (
    SELECT DISTINCT
        sm.sm_type
    FROM
        sales_data sd
    JOIN
        ship_mode sm ON sd.sm_type = sm.sm_type
)
SELECT
    tc.c_customer_sk,
    tc.order_count,
    tc.total_profit,
    tc.avg_order_value,
    sd.i_item_desc,
    sm.sm_type,
    sd.sales_date
FROM
    top_customers tc
LEFT JOIN
    sales_data sd ON sd.ws_order_number IN (
        SELECT
            ws_order_number
        FROM
            web_sales
        WHERE
            ws_bill_customer_sk = tc.c_customer_sk
    )
LEFT JOIN
    shipping_modes sm ON sd.sm_type = sm.sm_type
WHERE
    tc.rank <= 10
ORDER BY
    tc.total_profit DESC, 
    sd.sales_date DESC;
