
WITH sales_summary AS (
    SELECT
        d.d_year,
        d.d_moy,
        s.s_store_name,
        COUNT(ws.ws_order_number) AS total_sales,
        SUM(ws.ws_ext_sales_price) AS total_revenue,
        AVG(ws.ws_net_paid_inc_tax) AS average_order_value
    FROM
        web_sales ws
    JOIN
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN
        store s ON ws.ws_ship_addr_sk = s.s_addr_sk
    WHERE
        d.d_year BETWEEN 2021 AND 2023
    GROUP BY
        d.d_year, d.d_moy, s.s_store_name
),
top_stores AS (
    SELECT
        s.s_store_name,
        SUM(total_revenue) AS store_revenue
    FROM
        sales_summary s
    GROUP BY
        s.s_store_name
    ORDER BY
        store_revenue DESC
    LIMIT 5
)
SELECT
    t.s_store_name,
    ss.d_year,
    ss.d_moy,
    ss.total_sales,
    ss.total_revenue,
    ss.average_order_value
FROM
    sales_summary ss
JOIN
    top_stores t ON ss.s_store_name = t.s_store_name
ORDER BY
    t.store_revenue DESC, ss.d_year ASC, ss.d_moy ASC;
