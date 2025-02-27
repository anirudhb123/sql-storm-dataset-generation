
WITH sales_summary AS (
    SELECT
        ws_month.d_month AS sale_month,
        ws.s_ship_mode_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_profit) AS total_net_profit,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM
        web_sales AS ws
    JOIN
        date_dim AS ws_month ON ws.ws_sold_date_sk = ws_month.d_date_sk
    WHERE
        ws.ws_net_profit > 0
        AND ws_month.d_year = 2023
    GROUP BY
        ws_month.d_month, ws.s_ship_mode_sk
),
returns_summary AS (
    SELECT
        r.r_reason_sk,
        SUM(r.wr_return_quantity) AS total_returns,
        SUM(r.wr_return_amt) AS total_return_amount
    FROM
        web_returns AS r
    GROUP BY
        r.r_reason_sk
),
total_sales AS (
    SELECT
        ss.sale_month,
        sm.sm_ship_mode_id,
        ss.total_quantity,
        ss.total_net_profit,
        ISNULL(rs.total_returns, 0) AS total_returns,
        ISNULL(rs.total_return_amount, 0) AS total_return_amount
    FROM
        sales_summary AS ss
    LEFT JOIN
        ship_mode AS sm ON ss.s_ship_mode_sk = sm.sm_ship_mode_sk
    LEFT JOIN
        returns_summary AS rs ON ss.s_ship_mode_sk = rs.r_reason_sk
)
SELECT
    sale_month,
    sm_ship_mode_id,
    total_quantity,
    total_net_profit,
    total_returns,
    total_return_amount,
    (total_net_profit - total_return_amount) AS net_profit_after_returns,
    CASE 
        WHEN total_quantity > 1000 THEN 'High Volume'
        WHEN total_quantity BETWEEN 500 AND 1000 THEN 'Medium Volume'
        ELSE 'Low Volume'
    END AS volume_category
FROM
    total_sales
WHERE
    total_net_profit > 5000
ORDER BY
    sale_month, net_profit_after_returns DESC;
