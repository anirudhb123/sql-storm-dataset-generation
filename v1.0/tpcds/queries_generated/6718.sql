
WITH sales_summary AS (
    SELECT
        ws.web_site_id,
        COUNT(DISTINCT ws_order_number) AS total_orders,
        SUM(ws_sales_price) AS total_revenue,
        AVG(ws_net_profit) AS average_profit,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_ext_discount_amt) AS total_discount
    FROM
        web_sales ws
    JOIN
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE
        d.d_year = 2023 AND cd.cd_gender = 'F' AND cd.cd_marital_status = 'M'
    GROUP BY
        ws.web_site_id
),
address_summary AS (
    SELECT
        ca_state,
        COUNT(DISTINCT ca_address_id) AS distinct_addresses
    FROM
        customer_address ca
    JOIN
        customer c ON ca.ca_address_sk = c.c_current_addr_sk
    GROUP BY
        ca_state
)
SELECT
    ss.web_site_id,
    ss.total_orders,
    ss.total_revenue,
    ss.average_profit,
    ss.total_quantity,
    ss.total_discount,
    asu.distinct_addresses
FROM
    sales_summary ss
LEFT JOIN
    address_summary asu ON asu.ca_state = (
        SELECT
            ca_state
        FROM
            customer_address ca
        JOIN
            customer c ON ca.ca_address_sk = c.c_current_addr_sk
        WHERE
            c.c_customer_sk IN (SELECT ws_bill_customer_sk FROM web_sales WHERE ws_web_site_sk = ss.web_site_id)
        LIMIT 1
    )
ORDER BY
    ss.total_revenue DESC
LIMIT 10;
