
WITH RECURSIVE item_sales AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_paid_inc_tax) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_net_paid_inc_tax) DESC) AS rank
    FROM web_sales
    GROUP BY ws_item_sk
),
top_sales AS (
    SELECT 
        is.ws_item_sk,
        i.i_item_desc,
        is.total_quantity,
        is.total_sales,
        COALESCE(NULLIF(is.total_sales, 0), 1) AS sales_non_zero,
        COUNT(ws_order_number) OVER (PARTITION BY is.ws_item_sk) AS order_count
    FROM item_sales is
    JOIN item i ON is.ws_item_sk = i.i_item_sk
    WHERE is.rank <= 5
),
customer_info AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        hd.hd_income_band_sk,
        RANK() OVER (PARTITION BY cd.cd_gender ORDER BY COUNT(*) DESC) AS gender_rank
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status, hd.hd_income_band_sk
)
SELECT 
    si.ws_item_sk,
    ti.i_item_desc,
    ti.total_quantity,
    ti.total_sales,
    ci.c_customer_sk,
    ci.c_first_name,
    ci.c_last_name,
    ci.cd_gender,
    ci.cd_marital_status,
    ci.hd_income_band_sk
FROM top_sales ti
JOIN item_sales si ON ti.ws_item_sk = si.ws_item_sk
JOIN customer_info ci ON ci.gender_rank <= 3
LEFT JOIN store s ON s.s_store_sk = si.ws_item_sk
WHERE ti.total_quantity > 100
AND NOT EXISTS (
    SELECT 1
    FROM store_returns sr
    WHERE sr.sr_item_sk = si.ws_item_sk
    AND sr.sr_return_quantity > 0
)
ORDER BY ti.total_sales DESC
LIMIT 10;
