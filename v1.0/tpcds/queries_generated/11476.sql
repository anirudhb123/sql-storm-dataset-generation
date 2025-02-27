
WITH sales_summary AS (
    SELECT
        ws.ship_mode_sk,
        SUM(ws.net_profit) AS total_profit,
        COUNT(ws.order_number) AS total_orders
    FROM
        web_sales ws
    JOIN
        date_dim dd ON ws.sold_date_sk = dd.d_date_sk
    JOIN
        item it ON ws.item_sk = it.i_item_sk
    WHERE
        dd.d_year = 2023
    GROUP BY
        ws.ship_mode_sk
)
SELECT
    sm.ship_mode_id,
    sm.type,
    ss.total_profit,
    ss.total_orders
FROM
    sales_summary ss
JOIN
    ship_mode sm ON ss.ship_mode_sk = sm.sm_ship_mode_sk
ORDER BY
    ss.total_profit DESC;
