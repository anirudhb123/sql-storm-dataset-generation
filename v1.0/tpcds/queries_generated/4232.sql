
WITH sales_summary AS (
    SELECT
        d.d_year,
        sm.sm_type,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_profit) AS total_net_profit,
        AVG(ws.ws_net_paid_inc_tax) AS avg_net_paid
    FROM
        web_sales ws
    JOIN
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN
        ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    LEFT JOIN
        customer cust ON ws.ws_bill_customer_sk = cust.c_customer_sk
    WHERE
        d.d_year = 2023
        AND (cust.c_birth_year IS NULL OR cust.c_birth_year > 1980)
    GROUP BY
        d.d_year,
        sm.sm_type
),
returns_summary AS (
    SELECT
        d.d_year,
        sm.sm_type,
        SUM(sr_return_quantity) AS total_return_quantity,
        SUM(sr_return_amt) AS total_return_amount
    FROM
        store_returns sr
    JOIN
        date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN
        ship_mode sm ON sr.sr_ship_mode_sk = sm.sm_ship_mode_sk
    GROUP BY
        d.d_year,
        sm.sm_type
)
SELECT
    ss.d_year,
    ss.sm_type,
    ss.total_quantity,
    ss.total_net_profit,
    ss.avg_net_paid,
    COALESCE(rs.total_return_quantity, 0) AS total_return_quantity,
    COALESCE(rs.total_return_amount, 0) AS total_return_amount,
    (ss.total_net_profit - COALESCE(rs.total_return_amount, 0)) AS net_profit_after_returns
FROM
    sales_summary ss
LEFT JOIN
    returns_summary rs ON ss.d_year = rs.d_year AND ss.sm_type = rs.sm_type
ORDER BY
    ss.d_year, ss.sm_type;
