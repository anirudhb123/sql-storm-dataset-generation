
WITH customer_data AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating, 
        hd.hd_income_band_sk,
        hd.hd_buy_potential
    FROM
        customer c
    JOIN
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN
        household_demographics hd ON cd.cd_demo_sk = hd.hd_demo_sk
),
sales_data AS (
    SELECT
        ws.ws_bill_customer_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_profit) AS total_profit,
        MAX(ws.ws_sold_date_sk) AS last_purchase_date_sk
    FROM
        web_sales ws
    GROUP BY
        ws.ws_bill_customer_sk
),
ship_modes AS (
    SELECT
        sm.sm_ship_mode_sk,
        sm.sm_type,
        COUNT(ws.ws_ship_mode_sk) AS shipping_count
    FROM
        ship_mode sm
    LEFT JOIN
        web_sales ws ON sm.sm_ship_mode_sk = ws.ws_ship_mode_sk
    GROUP BY
        sm.sm_ship_mode_sk, sm.sm_type
)
SELECT
    cd.c_first_name,
    cd.c_last_name,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.cd_credit_rating,
    cd.hd_income_band_sk,
    cd.hd_buy_potential,
    COALESCE(sd.total_quantity, 0) AS total_quantity,
    COALESCE(sd.total_profit, 0) AS total_profit,
    sm.sm_type,
    sm.shipping_count,
    dd.d_date AS last_purchase_date
FROM
    customer_data cd
LEFT JOIN
    sales_data sd ON cd.c_customer_sk = sd.ws_bill_customer_sk
LEFT JOIN
    ship_modes sm ON sm.sm_ship_mode_sk = (
        SELECT ws.ws_ship_mode_sk
        FROM web_sales ws
        WHERE ws.ws_bill_customer_sk = cd.c_customer_sk
        ORDER BY ws.ws_sold_date_sk DESC
        LIMIT 1
    )
LEFT JOIN
    date_dim dd ON dd.d_date_sk = sd.last_purchase_date_sk
WHERE
    cd.cd_purchase_estimate > 1000
ORDER BY
    cd.c_last_name,
    cd.c_first_name;
