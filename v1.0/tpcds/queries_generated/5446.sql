
WITH recent_sales AS (
    SELECT
        ws.web_site_id,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_profit) AS total_profit,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        d.d_year,
        d.d_month_seq
    FROM
        web_sales ws
    JOIN
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE
        d.d_year >= 2022
    GROUP BY
        ws.web_site_id, d.d_year, d.d_month_seq
),
sales_counts AS (
    SELECT
        web_site_id,
        total_quantity,
        total_profit,
        total_orders,
        ROW_NUMBER() OVER (ORDER BY total_profit DESC) AS rank
    FROM
        recent_sales
),
top_websites AS (
    SELECT
        web_site_id,
        total_quantity,
        total_profit,
        total_orders
    FROM
        sales_counts
    WHERE
        rank <= 10
)
SELECT
    w.web_site_name,
    tw.total_quantity,
    tw.total_profit,
    tw.total_orders
FROM
    top_websites tw
JOIN
    web_site w ON tw.web_site_id = w.web_site_id
ORDER BY
    tw.total_profit DESC;
