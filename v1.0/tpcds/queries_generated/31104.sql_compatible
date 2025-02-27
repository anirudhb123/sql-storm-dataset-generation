
WITH RECURSIVE sales_data AS (
    SELECT
        ws_sold_date_sk,
        ws_ship_mode_sk,
        SUM(ws_net_profit) AS total_net_profit
    FROM
        web_sales
    WHERE
        ws_sold_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2022)
        AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2022)
    GROUP BY
        ws_sold_date_sk, ws_ship_mode_sk
    UNION ALL
    SELECT
        sr_returned_date_sk,
        sr_ship_mode_sk,
        -SUM(sr_return_amt) AS total_net_profit
    FROM
        store_returns sr
    LEFT JOIN
        ship_mode sm ON sr.sm_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE
        sr_returned_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2022)
        AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2022)
    GROUP BY
        sr_returned_date_sk, sr_ship_mode_sk
),
net_profit_summary AS (
    SELECT
        sales_data.ws_sold_date_sk,
        dm.d_month_seq,
        dm.d_year,
        sales_data.ws_ship_mode_sk,
        SUM(sales_data.total_net_profit) AS total_net_profit
    FROM
        sales_data
    JOIN
        date_dim dm ON dm.d_date_sk = sales_data.ws_sold_date_sk
    GROUP BY
        sales_data.ws_sold_date_sk, dm.d_month_seq, dm.d_year, sales_data.ws_ship_mode_sk
)
SELECT
    nps.ws_sold_date_sk,
    d.d_month_seq,
    d.d_year,
    sm.sm_type AS shipping_type,
    COALESCE(nps.total_net_profit, 0) AS profit_or_loss
FROM
    (SELECT DISTINCT d_month_seq, d_year FROM date_dim WHERE d_year = 2022) d
LEFT JOIN
    net_profit_summary nps ON nps.d_month_seq = d.d_month_seq AND nps.d_year = d.d_year
LEFT JOIN
    ship_mode sm ON nps.ws_ship_mode_sk = sm.sm_ship_mode_sk
ORDER BY
    d.d_month_seq, shipping_type;
