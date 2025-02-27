
WITH RECURSIVE sales_data AS (
    SELECT
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_ext_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_ext_sales_price) DESC) AS rank
    FROM web_sales
    GROUP BY ws_item_sk
),
customer_info AS (
    SELECT
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        ci.income_band_range
    FROM
        customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN (
        SELECT
            hd.hd_demo_sk,
            CONCAT(ib.ib_lower_bound, ' - ', ib.ib_upper_bound) AS income_band_range
        FROM
            household_demographics hd
        JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    ) ci ON ci.hd_demo_sk = c.c_current_hdemo_sk
),
top_selling_items AS (
    SELECT
        sd.ws_item_sk,
        sd.total_quantity,
        sd.total_sales
    FROM
        sales_data sd
    WHERE
        sd.rank <= 10
),
pedigree AS (
    SELECT
        ci.c_customer_id,
        COUNT(DISTINCT ci.cd_gender) AS unique_genders,
        SUM(CASE WHEN cd_purchase_estimate IS NOT NULL THEN 1 ELSE 0 END) AS active_customers
    FROM
        customer_info ci
    JOIN top_selling_items tsi ON ci.c_customer_id IN (
        SELECT DISTINCT ws_bill_customer_sk FROM web_sales
        WHERE ws_item_sk = tsi.ws_item_sk
    )
    GROUP BY ci.c_customer_id
)
SELECT
    pi.c_customer_id,
    pi.unique_genders,
    pi.active_customers,
    tsi.ws_item_sk,
    tsi.total_quantity,
    tsi.total_sales
FROM
    pedigree pi
JOIN top_selling_items tsi ON pi.c_customer_id IN (
    SELECT ws_bill_customer_sk FROM web_sales WHERE ws_item_sk = tsi.ws_item_sk
)
ORDER BY tsi.total_sales DESC, pi.active_customers DESC
LIMIT 100;

