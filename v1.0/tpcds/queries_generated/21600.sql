
WITH RECURSIVE customer_ages AS (
    SELECT 
        c.c_customer_sk,
        AGE(DATE(CONCAT(c.c_birth_year, '-', c.c_birth_month, '-', c.c_birth_day))) AS age
    FROM customer c
    WHERE c.c_birth_year IS NOT NULL AND c.c_birth_month IS NOT NULL AND c.c_birth_day IS NOT NULL
), sales_data AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_ext_sales_price) AS total_sales
    FROM web_sales ws
    WHERE ws.ws_sold_date_sk >= (SELECT d_date_sk FROM date_dim WHERE d_year = 2023 AND d_moy = 12 LIMIT 1)
    GROUP BY ws.ws_item_sk
), customer_demographics AS (
    SELECT
        cd.cd_demo_sk,
        cd.cd_gender,
        COALESCE(ib.ib_lower_bound, 0) AS income_lower,
        COALESCE(ib.ib_upper_bound, 100000) AS income_upper, 
        CASE 
            WHEN cd.cd_marital_status = 'M' THEN 'Married'
            WHEN cd.cd_marital_status = 'S' THEN 'Single'
            ELSE 'Other' 
        END AS marital_status
    FROM customer_demographics cd
    LEFT JOIN household_demographics hd ON cd.cd_demo_sk = hd.hd_demo_sk
    LEFT JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
), total_sales AS (
    SELECT 
        item.i_item_id,
        item.i_item_desc,
        sales.total_quantity,
        sales.total_sales,
        cd.income_lower,
        cd.income_upper
    FROM item
    JOIN sales_data sales ON item.i_item_sk = sales.ws_item_sk
    JOIN customer c ON c.c_customer_sk = (
        SELECT MIN(c.c_customer_sk) FROM customer c2 
        WHERE c2.c_current_cdemo_sk = c.c_current_cdemo_sk 
          AND c2.c_first_shipto_date_sk IS NOT NULL
    )
    LEFT JOIN customer_demographics cd ON cd.cd_demo_sk = c.c_current_cdemo_sk 
)
SELECT 
    t.i_item_id, 
    t.i_item_desc,
    t.total_quantity, 
    t.total_sales,
    cd.age,
    SUM(CASE 
        WHEN t.total_sales BETWEEN cd.income_lower AND cd.income_upper THEN 1 
        ELSE 0 
    END) OVER (PARTITION BY t.i_item_id) as sales_within_income_band
FROM total_sales t
LEFT JOIN customer_ages cd ON cd.c_customer_sk = (
    SELECT MIN(c_customer_sk) 
    FROM customer c2
    WHERE c2.c_current_cdemo_sk = (
        SELECT MIN(c.c_current_cdemo_sk) FROM customer c 
        WHERE c.c_customer_sk = t.ws_bill_customer_sk
    )
)
WHERE t.total_sales > 0 AND (cd.age IS NOT NULL OR cd.age IS NOT NULL)
ORDER BY t.total_sales DESC NULLS LAST;
