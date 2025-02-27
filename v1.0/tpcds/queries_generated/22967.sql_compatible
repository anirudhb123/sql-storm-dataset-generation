
WITH RECURSIVE income_bracket AS (
    SELECT
        ib_income_band_sk,
        ib_lower_bound,
        ib_upper_bound,
        ROW_NUMBER() OVER (ORDER BY ib_income_band_sk) AS rn
    FROM
        income_band
),
customer_info AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        hd.hd_income_band_sk,
        ROW_NUMBER() OVER (PARTITION BY hd.hd_buy_potential ORDER BY cd.cd_purchase_estimate DESC) AS rank
    FROM
        customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN household_demographics hd ON c.c_customer_sk = hd.hd_demo_sk
),
sales_data AS (
    SELECT
        ws.ws_sold_date_sk,
        SUM(ws.ws_net_profit) AS total_net_profit,
        SUM(ws.ws_quantity) AS total_quantity,
        ws.ws_item_sk,
        RANK() OVER (PARTITION BY ws.ws_sold_date_sk ORDER BY SUM(ws.ws_net_profit) DESC) AS sales_rank
    FROM
        web_sales ws
    WHERE
        ws.ws_sales_price > 0
    GROUP BY
        ws.ws_sold_date_sk, ws.ws_item_sk
),
date_info AS (
    SELECT
        d.d_date_id,
        d.d_month_seq,
        d.d_year,
        CASE 
            WHEN d.d_weekend = '1' THEN 'Weekend'
            ELSE 'Weekday'
        END AS day_type
    FROM
        date_dim d
)
SELECT DISTINCT
    ci.c_first_name,
    ci.c_last_name,
    ci.cd_gender,
    ci.cd_marital_status,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    di.d_date_id,
    di.d_month_seq,
    di.d_year,
    di.day_type,
    sd.total_net_profit,
    sd.total_quantity
FROM
    customer_info ci
JOIN income_bracket ib ON ci.hd_income_band_sk = ib.ib_income_band_sk
JOIN sales_data sd ON ci.c_customer_sk = sd.ws_item_sk
JOIN date_info di ON sd.ws_sold_date_sk = di.d_date_id
WHERE
    (ci.cd_purchase_estimate IS NOT NULL AND ci.cd_purchase_estimate > 100)
    AND (ci.rank <= 5 OR ci.rank IS NULL)
    AND (ib.ib_upper_bound - ib.ib_lower_bound) BETWEEN 10000 AND 50000
ORDER BY
    di.d_year DESC, di.d_month_seq ASC, sd.total_net_profit DESC;
