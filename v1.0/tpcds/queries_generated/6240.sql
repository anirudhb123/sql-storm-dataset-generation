
WITH sales_summary AS (
    SELECT
        ws.ws_ship_date_sk,
        ws.ws_ship_mode_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_sales_price * ws.ws_quantity) AS total_sales,
        SUM(ws.ws_ext_discount_amt) AS total_discount
    FROM web_sales ws
    INNER JOIN date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    INNER JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE dd.d_year = 2023
    GROUP BY ws.ws_ship_date_sk, ws.ws_ship_mode_sk
), 
customer_info AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        h.hd_income_band_sk
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN household_demographics h ON c.c_current_hdemo_sk = h.hd_demo_sk
), 
sales_with_customer AS (
    SELECT
        cs.c_customer_sk,
        SUM(ss.ss_quantity) AS total_quantity,
        SUM(ss.ss_sales_price * ss.ss_quantity) AS total_sales
    FROM store_sales ss
    INNER JOIN customer_info cs ON ss.ss_customer_sk = cs.c_customer_sk
    WHERE cs.hd_income_band_sk IS NOT NULL
    GROUP BY cs.c_customer_sk
)
SELECT
    ci.c_first_name,
    ci.c_last_name,
    ci.cd_gender,
    ci.cd_marital_status,
    COALESCE(swc.total_quantity, 0) AS total_store_quantity,
    COALESCE(swc.total_sales, 0) AS total_store_sales,
    COALESCE(ss.total_quantity, 0) AS total_web_quantity,
    COALESCE(ss.total_sales, 0) AS total_web_sales
FROM customer_info ci
LEFT JOIN sales_with_customer swc ON ci.c_customer_sk = swc.c_customer_sk
LEFT JOIN sales_summary ss ON ss.ws_ship_mode_sk = 1  -- Assuming we are interested in a specific ship mode
WHERE ci.hd_income_band_sk IS NOT NULL
ORDER BY total_web_sales DESC;
