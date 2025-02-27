
WITH sales_summary AS (
    SELECT
        w.w_warehouse_id,
        SUM(ws.ws_quantity) AS total_quantity_sold,
        SUM(ws.ws_ext_sales_price) AS total_sales_amount,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        AVG(ws.ws_net_profit) AS average_profit
    FROM
        web_sales ws
    JOIN
        warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE
        d.d_year = 2023
        AND d.d_month_seq BETWEEN 1 AND 6
    GROUP BY
        w.w_warehouse_id
),
customer_summary AS (
    SELECT
        ca.ca_city,
        COUNT(DISTINCT c.c_customer_sk) AS total_customers,
        COUNT(DISTINCT cr.cr_returning_customer_sk) AS total_returns,
        SUM(COALESCE(cr.cr_return_quantity, 0)) AS total_returned_quantity
    FROM
        customer c
    LEFT JOIN
        catalog_returns cr ON c.c_customer_sk = cr.cr_returning_customer_sk
    JOIN
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    GROUP BY
        ca.ca_city
)
SELECT
    ss.w_warehouse_id,
    ss.total_quantity_sold,
    ss.total_sales_amount,
    ss.total_orders,
    ss.average_profit,
    cs.ca_city,
    cs.total_customers,
    cs.total_returns,
    cs.total_returned_quantity
FROM
    sales_summary ss
JOIN
    customer_summary cs ON ss.w_warehouse_id = (
        SELECT
            w_warehouse_id
        FROM
            warehouse
        ORDER BY
            RANDOM()
        LIMIT 1
    )
ORDER BY
    ss.total_sales_amount DESC
LIMIT 10;
