
WITH ranked_sales AS (
    SELECT
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_quantity,
        ws.ws_sales_price,
        ws.ws_net_paid,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_net_paid DESC) AS sales_rank
    FROM
        web_sales AS ws
    WHERE
        ws.ws_sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2022)
),
customer_info AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        COALESCE(hd.hd_buy_potential, 'UNKNOWN') AS buy_potential,
        ib.ib_lower_bound,
        ib.ib_upper_bound
    FROM
        customer AS c
    LEFT JOIN customer_demographics AS cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN household_demographics AS hd ON cd.cd_demo_sk = hd.hd_demo_sk
    LEFT JOIN income_band AS ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE
        c.c_birth_year BETWEEN 1970 AND 1990
),
aggregate_returns AS (
    SELECT
        sr_customer_sk,
        SUM(sr_return_quantity) AS total_returned,
        SUM(sr_return_amt_inc_tax) AS total_returned_value
    FROM
        store_returns
    GROUP BY
        sr_customer_sk
)
SELECT
    ci.c_customer_sk,
    ci.c_first_name,
    ci.c_last_name,
    ci.cd_gender,
    ci.cd_marital_status,
    ci.buy_potential,
    SUM(rs.ws_quantity) AS total_quantity_sold,
    SUM(rs.ws_net_paid) AS total_sales_value,
    COALESCE(ar.total_returned, 0) AS total_returns,
    COALESCE(ar.total_returned_value, 0) AS total_returned_value
FROM
    customer_info AS ci
LEFT JOIN ranked_sales AS rs ON ci.c_customer_sk = rs.ws_order_number
LEFT JOIN aggregate_returns AS ar ON ci.c_customer_sk = ar.sr_customer_sk
WHERE
    ci.buy_potential <> 'UNKNOWN' AND
    (ci.cd_gender = 'F' OR ci.cd_marital_status = 'M')
GROUP BY
    ci.c_customer_sk,
    ci.c_first_name,
    ci.c_last_name,
    ci.cd_gender,
    ci.cd_marital_status,
    ci.buy_potential
HAVING
    SUM(rs.ws_net_paid) > 1000
ORDER BY
    total_sales_value DESC
LIMIT 10;
