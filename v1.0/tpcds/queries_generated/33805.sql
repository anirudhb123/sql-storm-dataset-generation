
WITH RECURSIVE sales_summary AS (
    SELECT
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_ext_sales_price) AS total_sales,
        SUM(ws_ext_discount_amt) AS total_discount,
        ws_sold_date_sk,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_ext_sales_price) DESC) AS rank
    FROM
        web_sales
    GROUP BY
        ws_item_sk, ws_sold_date_sk
),
customer_data AS (
    SELECT
        c.c_customer_sk,
        c.c_current_cdemo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        COALESCE(hd.hd_buy_potential, 'UNKNOWN') AS buy_potential,
        COALESCE(income.ib_lower_bound, 0) AS lower_income,
        COALESCE(income.ib_upper_bound, 999999) AS upper_income
    FROM
        customer AS c
    LEFT JOIN customer_demographics AS cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN household_demographics AS hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
    LEFT JOIN income_band AS income ON hd.hd_income_band_sk = income.ib_income_band_sk
),
sales_ranked AS (
    SELECT
        ss.ss_item_sk,
        ss.ss_store_sk,
        ss.ss_sold_date_sk,
        ss.ss_sales_price,
        ss.ss_ext_sales_price,
        ss.ss_net_paid,
        ROW_NUMBER() OVER (PARTITION BY ss.ss_item_sk ORDER BY ss.ss_net_paid DESC) AS store_rank
    FROM
        store_sales AS ss
)
SELECT
    c.c_customer_id,
    SUM(ss.total_sales) AS total_web_sales,
    SUM(sr.ss_net_paid) AS total_store_sales,
    SUM(ss.total_sales) - SUM(sr.ss_net_paid) AS net_difference,
    (CASE
        WHEN SUM(ss.total_sales) > SUM(sr.ss_net_paid) THEN 'Web Sales Dominant'
        WHEN SUM(ss.total_sales) < SUM(sr.ss_net_paid) THEN 'Store Sales Dominant'
        ELSE 'Equal Sales'
    END) AS sales_dominance,
    DATE_FORMAT(DATE_ADD(dd.d_date, INTERVAL 1 DAY), '%Y-%m-%d') AS next_day
FROM
    sales_summary ss
JOIN
    sales_ranked sr ON ss.ws_item_sk = sr.ss_item_sk
JOIN
    customer_data c ON c.c_current_cdemo_sk = ss.ws_item_sk
JOIN
    date_dim dd ON dd.d_date_sk = ss.ws_sold_date_sk
WHERE
    dd.d_year = 2023
    AND (c.cd_gender = 'M' OR c.cd_gender IS NULL)
GROUP BY
    c.c_customer_id
HAVING
    net_difference > 0
ORDER BY
    total_web_sales DESC, total_store_sales DESC;
