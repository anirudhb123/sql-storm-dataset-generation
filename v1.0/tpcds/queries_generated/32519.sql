
WITH RECURSIVE sales_data AS (
    SELECT 
        ws_order_number,
        ws_item_sk,
        ws_sales_price,
        ws_quantity,
        1 AS depth
    FROM web_sales
    WHERE ws_quantity > 0

    UNION ALL

    SELECT
        cs_order_number,
        cs_item_sk,
        cs_sales_price,
        cs_quantity,
        sd.depth + 1
    FROM catalog_sales cs
    JOIN sales_data sd ON cs.cs_order_number = sd.ws_order_number AND cs.cs_item_sk = sd.ws_item_sk
    WHERE cs.cs_quantity > 0 AND sd.depth < 5
),
customer_info AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        COALESCE(hd.hd_income_band_sk, 0) AS income_band_sk,
        RANK() OVER (PARTITION BY c.c_customer_sk ORDER BY c.c_birth_year DESC) AS rank_income
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
),
sales_summary AS (
    SELECT 
        si.c_customer_sk,
        SUM(si.ws_sales_price * si.ws_quantity) AS total_sales,
        MAX(si.ws_sales_price) AS max_sales_price,
        MIN(si.ws_sales_price) AS min_sales_price,
        COUNT(*) AS sales_count
    FROM sales_data si
    GROUP BY si.c_customer_sk
)
SELECT 
    ci.c_customer_sk,
    ci.c_first_name,
    ci.c_last_name,
    ci.cd_gender,
    CASE WHEN ss.total_sales IS NULL THEN 0 ELSE ss.total_sales END AS total_sales,
    ss.max_sales_price,
    ss.min_sales_price,
    ss.sales_count,
    ib.ib_lower_bound,
    ib.ib_upper_bound
FROM customer_info ci
LEFT JOIN sales_summary ss ON ci.c_customer_sk = ss.c_customer_sk
LEFT JOIN income_band ib ON ci.income_band_sk = ib.ib_income_band_sk
WHERE ci.rank_income = 1
ORDER BY total_sales DESC;
