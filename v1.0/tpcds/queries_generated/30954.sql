
WITH RECURSIVE sales_summary AS (
    SELECT
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_paid_inc_tax) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_net_paid_inc_tax) DESC) AS rank
    FROM web_sales
    GROUP BY ws_item_sk

    UNION ALL

    SELECT
        ss_item_sk,
        SUM(ss_quantity) AS total_quantity,
        SUM(ss_net_paid_inc_tax) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ss_item_sk ORDER BY SUM(ss_net_paid_inc_tax) DESC) AS rank
    FROM store_sales
    GROUP BY ss_item_sk
)

SELECT
    i.i_item_id,
    i.i_item_desc,
    COALESCE(ss.total_quantity, 0) AS web_sales_quantity,
    COALESCE(ss2.total_quantity, 0) AS store_sales_quantity,
    COALESCE(ss.total_sales, 0) AS web_sales_amount,
    COALESCE(ss2.total_sales, 0) AS store_sales_amount,
    (COALESCE(ss.total_sales, 0) + COALESCE(ss2.total_sales, 0)) AS total_sales_amount,
    CASE
        WHEN COALESCE(ss.total_sales, 0) > COALESCE(ss2.total_sales, 0) THEN 'Web'
        WHEN COALESCE(ss.total_sales, 0) < COALESCE(ss2.total_sales, 0) THEN 'Store'
        ELSE 'Equal'
    END AS sales_comparison
FROM
    item i
LEFT JOIN sales_summary ss ON i.i_item_sk = ss.ws_item_sk
LEFT JOIN sales_summary ss2 ON i.i_item_sk = ss2.ss_item_sk AND ss2.rank = 1
WHERE
    (i.i_current_price IS NOT NULL) AND
    (i.i_rec_start_date <= CURRENT_DATE AND (i.i_rec_end_date IS NULL OR i.i_rec_end_date >= CURRENT_DATE))
ORDER BY
    total_sales_amount DESC
LIMIT 100
OFFSET 0;
