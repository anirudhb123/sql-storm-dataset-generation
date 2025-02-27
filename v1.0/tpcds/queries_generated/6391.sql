
WITH customer_info AS (
    SELECT
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_income_band_sk,
        hd.hd_income_band_sk AS household_income_band
    FROM
        customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN household_demographics hd ON cd.cd_demo_sk = hd.hd_demo_sk
),
sales_data AS (
    SELECT
        ws.ws_order_number,
        ws.ws_item_sk,
        ws.ws_sales_price,
        ws.ws_quantity,
        d.d_year,
        sm.sm_type,
        ci.c_customer_id
    FROM
        web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN customer_info ci ON ws.ws_bill_customer_sk = ci.c_customer_sk
),
aggregate_sales AS (
    SELECT
        ci.c_customer_id,
        si.s_ship_mode,
        sa.d_year,
        SUM(sa.ws_sales_price * sa.ws_quantity) AS total_sales,
        COUNT(sa.ws_order_number) AS total_orders
    FROM
        sales_data sa
    JOIN customer_info ci ON sa.c_customer_id = ci.c_customer_id
    GROUP BY
        ci.c_customer_id,
        sa.sm_type,
        sa.d_year
),
income_band_analysis AS (
    SELECT
        ci.household_income_band,
        AVG(as.total_sales) AS average_sales,
        AVG(as.total_orders) AS average_orders
    FROM
        aggregate_sales as
    JOIN customer_info ci ON as.c_customer_id = ci.c_customer_id
    GROUP BY
        ci.household_income_band
)
SELECT 
    iba.household_income_band,
    iba.average_sales,
    iba.average_orders
FROM 
    income_band_analysis iba
WHERE 
    iba.average_sales > (SELECT AVG(average_sales) FROM income_band_analysis)
ORDER BY 
    iba.average_sales DESC;
