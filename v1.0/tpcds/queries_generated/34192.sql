
WITH RECURSIVE date_series AS (
    SELECT d_date_sk, d_date, d_year
    FROM date_dim
    WHERE d_date >= '2022-01-01' AND d_date <= '2022-12-31'
    UNION ALL
    SELECT d.d_date_sk, d.d_date, d.d_year
    FROM date_dim d
    JOIN date_series ds ON d.d_date_sk = ds.d_date_sk + 1
),
sales_info AS (
    SELECT 
        ws_order_number,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_sales_price) AS total_sales_price,
        ws_item_sk,
        ws_ship_mode_sk,
        ws_bill_customer_sk,
        ws_sold_date_sk
    FROM web_sales
    GROUP BY ws_order_number, ws_item_sk, ws_ship_mode_sk, ws_bill_customer_sk, ws_sold_date_sk
),
shipping_modes AS (
    SELECT sm.sm_ship_mode_id, sm.sm_type, sm.sm_carrier
    FROM ship_mode sm
),
customer_data AS (
    SELECT 
        c.c_customer_sk,
        COALESCE(cd.cd_gender, 'Unknown') AS gender,
        COALESCE(hd.hd_income_band_sk, 0) AS income_band,
        COUNT(DISTINCT CASE WHEN r.r_reason_desc IS NOT NULL THEN r.r_reason_desc END) AS return_reasons
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
    LEFT JOIN store_returns sr ON c.c_customer_sk = sr.sr_customer_sk
    LEFT JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    GROUP BY c.c_customer_sk, cd.cd_gender, hd.hd_income_band_sk
),
sales_summary AS (
    SELECT 
        ds.d_year,
        sd.gender,
        sm.sm_type,
        SUM(si.total_quantity) AS year_quantity,
        SUM(si.total_sales_price) AS year_sales
    FROM date_series ds
    JOIN sales_info si ON ds.d_date_sk = si.ws_sold_date_sk
    JOIN customer_data sd ON si.ws_bill_customer_sk = sd.c_customer_sk
    JOIN shipping_modes sm ON si.ws_ship_mode_sk = sm.sm_ship_mode_id
    GROUP BY ds.d_year, sd.gender, sm.sm_type
    ORDER BY ds.d_year, sd.gender, sm.sm_type
)
SELECT 
    d_year,
    gender,
    sm_type,
    year_quantity,
    year_sales,
    CASE 
        WHEN year_sales IS NULL THEN 'No Sales'
        ELSE 'Sales Recorded'
    END AS sales_status
FROM sales_summary
WHERE year_sales > 5000 OR (gender = 'M' AND year_quantity > 50)
ORDER BY d_year, gender DESC;
