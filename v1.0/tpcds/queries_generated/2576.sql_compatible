
WITH Ranked_Sales AS (
    SELECT
        cs.cs_item_sk,
        cs.cs_order_number,
        cs.cs_sales_price,
        cs.cs_ext_sales_price,
        ROW_NUMBER() OVER (PARTITION BY cs.cs_item_sk ORDER BY cs.cs_sold_date_sk DESC) AS sales_rank
    FROM
        catalog_sales cs
    WHERE
        cs.cs_sales_price > 0
),
Recent_Returns AS (
    SELECT
        cr.cr_item_sk,
        SUM(cr.cr_return_quantity) AS total_returns,
        COUNT(cr.cr_return_number) AS return_count
    FROM
        catalog_returns cr
    WHERE
        cr.cr_returned_date_sk >= (
            SELECT MAX(d.d_date_sk)
            FROM date_dim d
            WHERE d.d_year = 2023 AND d.d_moy = 10
        )
    GROUP BY
        cr.cr_item_sk
),
Sales_Correction AS (
    SELECT
        rs.cs_item_sk,
        rs.cs_order_number,
        rs.cs_sales_price - COALESCE(rr.total_returns, 0) AS adjusted_sales_price,
        CASE 
            WHEN rr.return_count IS NOT NULL AND rr.return_count > 0 THEN 'Adjusted by Returns'
            ELSE 'No Adjustments'
        END AS adjustment_reason
    FROM
        Ranked_Sales rs
    LEFT JOIN
        Recent_Returns rr ON rs.cs_item_sk = rr.cr_item_sk
)
SELECT
    sc.cs_item_sk,
    COUNT(sc.cs_order_number) AS adjusted_order_count,
    AVG(sc.adjusted_sales_price) AS avg_adjusted_sales_price,
    sc.adjustment_reason
FROM
    Sales_Correction sc
WHERE
    sc.adjusted_sales_price > 0
GROUP BY
    sc.cs_item_sk,
    sc.adjustment_reason
ORDER BY
    adjusted_order_count DESC,
    avg_adjusted_sales_price DESC
LIMIT 10;
