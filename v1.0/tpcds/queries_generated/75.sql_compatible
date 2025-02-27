
WITH sales_data AS (
    SELECT
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_paid) AS total_net_paid,
        DENSE_RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_net_paid) DESC) AS rank_per_item
    FROM
        web_sales ws
    INNER JOIN
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE
        dd.d_year = 2023
    GROUP BY
        ws.ws_item_sk
),
customer_data AS (
    SELECT
        c.c_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_income_band_sk,
        hd.hd_buy_potential
    FROM
        customer c
    LEFT JOIN
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN
        household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
    WHERE
        hd.hd_income_band_sk IS NOT NULL
),
top_sales AS (
    SELECT
        item.i_item_id,
        item.i_item_desc,
        sd.total_quantity,
        sd.total_net_paid
    FROM
        sales_data sd
    INNER JOIN
        item item ON sd.ws_item_sk = item.i_item_sk
    WHERE
        sd.rank_per_item <= 10
)
SELECT
    cs.c_customer_sk,
    cs.cd_gender,
    cs.cd_marital_status,
    cs.hd_buy_potential,
    ts.i_item_id,
    ts.i_item_desc,
    ts.total_quantity,
    ts.total_net_paid
FROM
    customer_data cs
LEFT JOIN
    top_sales ts ON cs.c_customer_sk IN (
        SELECT DISTINCT
            ws.ws_bill_customer_sk
        FROM
            web_sales ws
        WHERE
            ws.ws_net_paid > 0
            AND ws.ws_item_sk IN (SELECT ws_item_sk FROM sales_data WHERE total_net_paid > 50)
    )
ORDER BY
    cs.c_customer_sk,
    ts.total_net_paid DESC
LIMIT 100;
