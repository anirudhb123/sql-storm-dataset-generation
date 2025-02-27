
WITH RECURSIVE income_bracket AS (
    SELECT ib_income_band_sk, ib_lower_bound, ib_upper_bound
    FROM income_band
    WHERE ib_lower_bound IS NOT NULL
    UNION ALL
    SELECT ib.ib_income_band_sk, ib.ib_lower_bound + 1, ib.ib_upper_bound
    FROM income_band ib
    JOIN income_bracket ib_rec ON ib.ib_income_band_sk = ib_rec.ib_income_band_sk
    WHERE ib_rec.ib_lower_bound < ib_rec.ib_upper_bound
),
customer_data AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating,
        CASE 
            WHEN cd.cd_dep_count IS NULL THEN 'N/A'
            ELSE CAST(cd.cd_dep_count AS VARCHAR)
        END AS total_dependents,
        ib.ib_lower_bound,
        ib.ib_upper_bound
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
    LEFT JOIN income_bracket ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE cd.cd_purchase_estimate IS NOT NULL 
      AND (cd.cd_marital_status IN ('M', 'S') OR cd.cd_gender IS NULL)
),
sales_data AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_web_site_sk,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS order_count,
        RANK() OVER (PARTITION BY ws.ws_web_site_sk ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS sales_rank
    FROM web_sales ws
    WHERE ws.ws_sold_date_sk < (SELECT MAX(d.d_date_sk) FROM date_dim d WHERE d.d_year = 2022)
    GROUP BY ws.ws_order_number, ws.ws_web_site_sk
),
aggregate_sales AS (
    SELECT 
        ws.web_site_sk,
        SUM(ws.total_sales) AS site_total_sales,
        COUNT(ws.order_count) AS total_orders
    FROM sales_data ws
    WHERE ws.sales_rank <= 5
    GROUP BY ws.web_site_sk
)
SELECT 
    cd.c_customer_id,
    cd.c_first_name,
    cd.c_last_name,
    cd.total_dependents,
    COALESCE(agg.site_total_sales, 0) AS total_sales_site,
    COALESCE(agg.total_orders, 0) AS total_orders_site,
    CASE 
        WHEN cd.ib_lower_bound IS NOT NULL AND cd.ib_upper_bound IS NOT NULL THEN 
            (cd.ib_lower_bound + cd.ib_upper_bound) / 2.0
        ELSE NULL
    END AS average_income_band,
    ROW_NUMBER() OVER (ORDER BY cd.c_last_name, cd.c_first_name) AS customer_rank
FROM customer_data cd
LEFT JOIN aggregate_sales agg ON cd.c_current_addr_sk = agg.web_site_sk
ORDER BY customer_rank
OFFSET 10 ROWS FETCH NEXT 50 ROWS ONLY;
