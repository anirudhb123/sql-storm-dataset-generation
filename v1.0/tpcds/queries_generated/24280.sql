
WITH ranked_sales AS (
    SELECT
        ss_store_sk,
        ss_item_sk,
        SUM(ss_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ss_store_sk ORDER BY SUM(ss_sales_price) DESC) AS sales_rank
    FROM
        store_sales
    GROUP BY
        ss_store_sk,
        ss_item_sk
),
top_sales AS (
    SELECT
        rs.ss_store_sk,
        rs.ss_item_sk,
        rs.total_sales,
        CASE
            WHEN (rs.total_sales IS NULL) THEN 'Unknown Sales'
            WHEN (rs.total_sales < 0) THEN 'Negative Sales'
            ELSE 'Positive Sales'
        END AS sales_category
    FROM
        ranked_sales rs
    WHERE
        rs.sales_rank <= 3
),
average_sales AS (
    SELECT
        ss_store_sk,
        AVG(total_sales) AS avg_sales
    FROM
        top_sales
    GROUP BY
        ss_store_sk
)
SELECT
    s.s_store_name,
    ts.item_sales,
    COALESCE(avs.avg_sales, 0) AS avg_sales,
    CASE
        WHEN avs.avg_sales > ts.item_sales THEN 'Above Average'
        WHEN avs.avg_sales < ts.item_sales THEN 'Below Average'
        ELSE 'At Average'
    END AS sales_comparison
FROM
    store s
LEFT JOIN (
    SELECT
        ts.ss_store_sk,
        SUM(ts.total_sales) AS item_sales
    FROM
        top_sales ts
    GROUP BY
        ts.ss_store_sk
) ts ON s.s_store_sk = ts.ss_store_sk
LEFT JOIN average_sales avs ON s.s_store_sk = avs.ss_store_sk
WHERE
    s.s_state = 'CA' AND
    NOT EXISTS (
        SELECT 1 
        FROM catalog_sales cs 
        WHERE cs.cs_ship_mode_sk = (SELECT sm_ship_mode_sk FROM ship_mode WHERE sm_type = 'STANDARD') 
        AND cs.cs_customer_sk = s.s_store_sk
    )
ORDER BY
    s.s_store_name;
