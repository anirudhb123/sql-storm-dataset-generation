
WITH RankedReturns AS (
    SELECT
        sr_returned_date_sk,
        sr_item_sk,
        sr_customer_sk,
        sr_return_quantity,
        sr_return_amt,
        ROW_NUMBER() OVER (PARTITION BY sr_item_sk ORDER BY sr_returned_date_sk DESC) AS rn
    FROM store_returns
    WHERE sr_return_quantity > 0
),
TotalReturns AS (
    SELECT
        sr_item_sk,
        SUM(sr_return_quantity) AS total_return_qty,
        SUM(sr_return_amt) AS total_return_amt
    FROM RankedReturns
    WHERE rn = 1
    GROUP BY sr_item_sk
),
ItemDetails AS (
    SELECT
        i.i_item_sk,
        i.i_product_name,
        i.i_current_price,
        COALESCE(tr.total_return_qty, 0) AS total_return_qty,
        COALESCE(tr.total_return_amt, 0) AS total_return_amt,
        CASE 
            WHEN COALESCE(tr.total_return_qty, 0) = 0 THEN 'No Returns'
            WHEN COALESCE(tr.total_return_qty, 0) > 5 THEN 'High Returns'
            ELSE 'Moderate Returns'
        END AS return_category
    FROM item i
    LEFT JOIN TotalReturns tr ON i.i_item_sk = tr.sr_item_sk
)
SELECT
    id.i_item_sk,
    id.i_product_name,
    ROUND(id.i_current_price, 2) AS formatted_price,
    id.total_return_qty,
    id.total_return_amt,
    id.return_category,
    CASE
        WHEN id.total_return_qty IS NULL THEN 'No Returns Recorded'
        ELSE CONCAT('Total Returns: ', id.total_return_qty)
    END AS return_info,
    (SELECT COUNT(DISTINCT cs_order_number)
     FROM catalog_sales cs
     WHERE cs.cs_item_sk = id.i_item_sk) AS order_count,
    (SELECT AVG(ds.d_year) 
     FROM date_dim ds
     WHERE ds.d_date_sk IN (SELECT ws.web_site_sk 
                            FROM web_sales ws 
                            WHERE ws.ws_item_sk = id.i_item_sk)
        AND ds.d_year IS NOT NULL) AS avg_year_bought
FROM ItemDetails id
WHERE id.return_category IN ('High Returns', 'No Returns')
ORDER BY id.total_return_qty DESC, id.i_product_name;
