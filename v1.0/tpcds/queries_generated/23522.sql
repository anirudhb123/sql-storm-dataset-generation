
WITH RankedReturns AS (
    SELECT
        sr_item_sk,
        COUNT(*) AS total_returns,
        SUM(sr_return_quantity) AS sum_return_quantity,
        ROW_NUMBER() OVER (PARTITION BY sr_item_sk ORDER BY SUM(sr_return_quantity) DESC) AS rn
    FROM
        store_returns
    GROUP BY
        sr_item_sk
),
FilteredReturns AS (
    SELECT
        r.*,
        (SELECT COUNT(*)
         FROM store s
         WHERE s.s_store_sk = sr.s_store_sk) AS store_count
    FROM
        RankedReturns r
    JOIN store_returns sr ON r.sr_item_sk = sr.sr_item_sk
    WHERE
        sr_return_quantity > (SELECT AVG(sr_return_quantity) FROM store_returns) 
        AND total_returns > 1
),
MaxReturnPerItem AS (
    SELECT
        sr_item_sk,
        MAX(sum_return_quantity) AS max_return_quantity
    FROM
        FilteredReturns
    GROUP BY
        sr_item_sk
)
SELECT
    f.*,
    CASE 
        WHEN MAX_RETURN.max_return_quantity IS NOT NULL THEN 'High Return'
        ELSE 'Low Return'
    END AS return_category
FROM
    FilteredReturns f
LEFT JOIN MaxReturnPerItem MAX_RETURN ON f.sr_item_sk = MAX_RETURN.sr_item_sk
WHERE 
    EXISTS (SELECT 1 
            FROM item i 
            WHERE i.i_item_sk = f.sr_item_sk 
            AND i.i_current_price IS NOT NULL
            AND i.i_current_price > 
                (SELECT AVG(i2.i_current_price) FROM item i2))
ORDER BY 
    f.sum_return_quantity DESC, 
    f.total_returns ASC;

```
