
WITH RankedReturns AS (
    SELECT
        sr.customer_sk,
        SUM(sr.return_quantity) AS total_returned,
        ROW_NUMBER() OVER (PARTITION BY sr.customer_sk ORDER BY SUM(sr.return_quantity) DESC) as rn
    FROM store_returns sr
    GROUP BY sr.customer_sk
),
CustomerDetails AS (
    SELECT
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        SUM(CASE WHEN sr.return_quantity IS NOT NULL THEN sr.return_quantity ELSE 0 END) AS total_return_quantity,
        RANK() OVER (PARTITION BY cd.cd_gender ORDER BY SUM(CASE WHEN sr.return_quantity IS NOT NULL THEN sr.return_quantity ELSE 0 END) DESC) AS gender_rank
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN store_returns sr ON c.c_customer_sk = sr.sr_customer_sk
    WHERE cd.cd_marital_status IS NOT NULL
    GROUP BY c.c_customer_id, cd.cd_gender, cd.cd_marital_status
),
MedianIncome AS (
    SELECT
        hd.hd_income_band_sk,
        PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY cs.cs_sales_price) AS median_sales_price
    FROM catalog_sales cs
    JOIN household_demographics hd ON cs.cs_ship_customer_sk = hd.hd_demo_sk
    GROUP BY hd.hd_income_band_sk
),
ReturnReasons AS (
    SELECT
        r.r_reason_desc,
        COUNT(*) AS return_count
    FROM reason r
    JOIN store_returns sr ON r.r_reason_sk = sr.sr_reason_sk
    GROUP BY r.r_reason_desc
    HAVING COUNT(*) > 10
)
SELECT
    cd.c_customer_id,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.total_return_quantity,
    CASE 
        WHEN cd.gender_rank = 1 THEN 'Most Returns'
        WHEN cd.gender_rank <= 5 THEN 'Top 5 Returns'
        ELSE 'Other'
    END AS return_category,
    mi.median_sales_price,
    rr.return_count,
    COALESCE(rr.return_count, 0) AS reason_return_count,
    ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY cd.total_return_quantity DESC) AS gender_based_ranking
FROM CustomerDetails cd
LEFT JOIN MedianIncome mi ON cd.total_return_quantity >= mi.median_sales_price
LEFT JOIN ReturnReasons rr ON cd.c_customer_id = rr.r_reason_desc
WHERE cd.total_return_quantity > 0
  AND EXISTS (
      SELECT 1
      FROM warehouse w
      WHERE w.w_warehouse_name IS NOT NULL
      AND w.w_warehouse_sq_ft > 5000
      AND w.w_country != 'USA'
  )
ORDER BY cd.total_return_quantity DESC, cd.c_customer_id
FETCH FIRST 100 ROWS ONLY;
