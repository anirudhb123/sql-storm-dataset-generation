
WITH ranked_sales AS (
    SELECT
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_sales_price) AS total_sales,
        DENSE_RANK() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_sales_price) DESC) AS rank_sales
    FROM
        web_sales
    GROUP BY
        ws_item_sk
),
customer_income AS (
    SELECT
        c.c_customer_sk,
        CASE
            WHEN h.hd_income_band_sk IS NULL THEN 'Unknown'
            WHEN h.hd_income_band_sk BETWEEN 1 AND 5 THEN 'Low'
            WHEN h.hd_income_band_sk BETWEEN 6 AND 10 THEN 'Medium'
            ELSE 'High'
        END AS income_group
    FROM
        customer c
    LEFT JOIN household_demographics h ON c.c_current_hdemo_sk = h.hd_demo_sk
),
high_value_customers AS (
    SELECT
        ci.c_customer_sk,
        ci.income_group,
        ROW_NUMBER() OVER (PARTITION BY ci.income_group ORDER BY SUM(ws.total_sales) DESC) AS customer_rank
    FROM
        customer_income ci
    JOIN ranked_sales rs ON rs.ws_item_sk IN (
        SELECT cr_item_sk FROM catalog_returns WHERE cr_return_quantity > 0
    )
    GROUP BY
        ci.c_customer_sk, ci.income_group
),
date_filter AS (
    SELECT d_date_sk
    FROM date_dim
    WHERE d_date BETWEEN '2023-01-01' AND '2023-12-31'
)
SELECT
    c.c_customer_id,
    d.d_date_id,
    cv.income_group,
    SUM(COALESCE(cs.cs_quantity, 0)) AS total_catalog_sales,
    SUM(COALESCE(store.ss_quantity, 0)) AS total_store_sales
FROM
    customer c
LEFT JOIN high_value_customers cv ON c.c_customer_sk = cv.c_customer_sk
LEFT JOIN catalog_sales cs ON c.c_customer_sk = cs.cs_bill_customer_sk
LEFT JOIN store_sales store ON c.c_customer_sk = store.ss_customer_sk
JOIN date_filter d ON (cs.cs_sold_date_sk = d.d_date_sk OR store.ss_sold_date_sk = d.d_date_sk)
WHERE
    (cv.customer_rank IS NULL OR cv.customer_rank <= 10)
    AND (c.c_birth_year IS NOT NULL OR c.c_current_cdemo_sk IS NOT NULL)
GROUP BY
    c.c_customer_id, d.d_date_id, cv.income_group
HAVING
    SUM(COALESCE(cs.cs_quantity, 0)) + SUM(COALESCE(store.ss_quantity, 0)) > 100
ORDER BY
    total_catalog_sales DESC, total_store_sales ASC;
