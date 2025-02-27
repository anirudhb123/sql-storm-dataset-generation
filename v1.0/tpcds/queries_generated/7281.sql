
WITH sales_data AS (
    SELECT
        ws.sold_date_sk,
        ws.item_sk,
        ws.quantity,
        ws.net_profit,
        i.item_desc,
        c.c_current_cdemo_sk,
        d.d_year,
        d.d_month_seq,
        sm.sm_type
    FROM
        web_sales ws
    JOIN
        item i ON ws.item_sk = i.i_item_sk
    JOIN
        customer c ON ws.bill_customer_sk = c.c_customer_sk
    JOIN
        date_dim d ON ws.sold_date_sk = d.d_date_sk
    JOIN
        ship_mode sm ON ws.ship_mode_sk = sm.sm_ship_mode_sk
    WHERE
        d.d_year = 2023
        AND sm.sm_type IN ('Ground', 'Express')
),
profit_analysis AS (
    SELECT
        sold_date_sk,
        item_sk,
        SUM(quantity) AS total_quantity,
        SUM(net_profit) AS total_profit,
        COUNT(DISTINCT c_current_cdemo_sk) AS unique_customers,
        d_month_seq
    FROM
        sales_data
    GROUP BY
        sold_date_sk, item_sk, d_month_seq
)
SELECT
    d_month_seq,
    item_sk,
    total_quantity,
    total_profit,
    unique_customers,
    RANK() OVER (PARTITION BY d_month_seq ORDER BY total_profit DESC) AS profit_rank
FROM
    profit_analysis
WHERE
    total_profit > 0
ORDER BY
    d_month_seq, profit_rank;
