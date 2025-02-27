
WITH sales_summary AS (
    SELECT
        c.c_customer_id,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS total_orders,
        AVG(ws.ws_net_profit) AS avg_net_profit,
        COUNT(DISTINCT ws.ws_item_sk) AS unique_items_sold
    FROM
        customer c
    JOIN
        web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    JOIN
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE
        dd.d_year = 2023
    GROUP BY
        c.c_customer_id
),
high_value_customers AS (
    SELECT
        c.c_customer_id,
        ss.total_sales,
        ss.total_orders,
        ss.avg_net_profit,
        ss.unique_items_sold,
        RANK() OVER (ORDER BY ss.total_sales DESC) AS sales_rank
    FROM
        sales_summary ss
    JOIN
        customer c ON ss.c_customer_id = c.c_customer_id
    WHERE
        ss.total_sales > 1000
)
SELECT
    hv.c_customer_id,
    hv.total_sales,
    hv.total_orders,
    hv.avg_net_profit,
    hv.unique_items_sold,
    hv.sales_rank,
    ca.ca_city,
    ca.ca_state,
    ca.ca_country
FROM
    high_value_customers hv
JOIN
    customer_address ca ON ca.ca_address_sk = c.c_current_addr_sk
WHERE
    hv.sales_rank <= 10
ORDER BY
    hv.total_sales DESC;
