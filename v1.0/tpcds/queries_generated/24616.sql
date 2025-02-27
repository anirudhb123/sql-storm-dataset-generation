
WITH RECURSIVE income_band_data AS (
    SELECT
        ib_income_band_sk,
        ib_lower_bound,
        ib_upper_bound,
        1 AS level
    FROM
        income_band
    WHERE
        ib_lower_bound IS NOT NULL

    UNION ALL

    SELECT
        ib.ib_income_band_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        id.level + 1
    FROM
        income_band_data id
    JOIN
        income_band ib ON ib.ib_lower_bound BETWEEN id.ib_lower_bound AND id.ib_upper_bound
        AND id.level < 5
),
combined_sales AS (
    SELECT
        ss.ss_item_sk,
        ss.ss_sales_price,
        ss.ss_quantity,
        ss.ss_ext_sales_price,
        'store' AS source
    FROM
        store_sales ss
    WHERE
        ss.ss_quantity > 0
    UNION ALL
    SELECT
        cs.cs_item_sk,
        cs.cs_sales_price,
        cs.cs_quantity,
        cs.cs_ext_sales_price,
        'catalog' AS source
    FROM
        catalog_sales cs
    WHERE
        cs.cs_quantity > 0
),
aggregated_sales AS (
    SELECT
        cs.ss_item_sk,
        SUM(cs.ss_quantity) AS total_quantity,
        SUM(cs.ss_ext_sales_price) AS total_sales,
        MAX(cs.ss_sales_price) AS max_price,
        MIN(cs.ss_sales_price) AS min_price
    FROM
        combined_sales cs
    GROUP BY
        cs.ss_item_sk
),
final_analysis AS (
    SELECT
        a.ss_item_sk,
        a.total_quantity,
        a.total_sales,
        a.max_price,
        a.min_price,
        b.ib_lower_bound,
        b.ib_upper_bound,
        CASE
            WHEN a.total_sales > 100000 THEN 'High Value'
            WHEN a.total_sales BETWEEN 50000 AND 100000 THEN 'Medium Value'
            ELSE 'Low Value'
        END AS sales_category
    FROM
        aggregated_sales a
    LEFT JOIN
        income_band_data b ON a.total_sales BETWEEN b.ib_lower_bound AND b.ib_upper_bound
),
ranked_analysis AS (
    SELECT
        *,
        ROW_NUMBER() OVER (PARTITION BY sales_category ORDER BY total_sales DESC) AS rank
    FROM
        final_analysis
)
SELECT
    r.ss_item_sk,
    r.sales_category,
    r.total_quantity,
    r.total_sales,
    r.max_price,
    r.min_price,
    r.ib_lower_bound,
    r.ib_upper_bound
FROM
    ranked_analysis r
WHERE
    r.rank <= 10
ORDER BY
    r.sales_category,
    r.total_sales DESC;
