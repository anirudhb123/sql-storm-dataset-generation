
WITH RECURSIVE ItemHierarchy AS (
    SELECT i_item_sk, i_item_id, i_product_name, i_current_price, 1 AS depth
    FROM item
    WHERE i_current_price IS NOT NULL
    UNION ALL
    SELECT i.i_item_sk, i.i_item_id, i.i_product_name, i.i_current_price, ih.depth + 1
    FROM item i
    JOIN ItemHierarchy ih ON ih.i_item_sk = i.i_item_sk
    WHERE ih.depth < 5
),
CustomerReturns AS (
    SELECT sr.returned_date_sk, sr.store_sk, sr.item_sk, 
           SUM(sr.return_quantity) AS total_returned, 
           SUM(sr.return_amt) AS total_return_amount
    FROM store_returns sr
    GROUP BY sr.returned_date_sk, sr.store_sk, sr.item_sk
),
SalesSummary AS (
    SELECT ws_sold_date_sk, ws_item_sk,
           SUM(ws_quantity) AS total_sold, 
           SUM(ws_net_profit) AS total_net_profit
    FROM web_sales
    WHERE ws_sold_date_sk BETWEEN 20200101 AND 20201231
    GROUP BY ws_sold_date_sk, ws_item_sk
),
CombinedResults AS (
    SELECT 
        ih.i_item_id,
        ih.i_product_name,
        COALESCE(cs.total_sold, 0) AS total_sales,
        COALESCE(cr.total_returned, 0) AS total_returns,
        (COALESCE(cs.total_sold, 0) - COALESCE(cr.total_returned, 0)) AS net_sales,
        ih.i_current_price,
        ih.depth
    FROM ItemHierarchy ih
    LEFT JOIN SalesSummary cs ON ih.i_item_sk = cs.ws_item_sk
    LEFT JOIN CustomerReturns cr ON ih.i_item_sk = cr.item_sk
)
SELECT 
    cb.i_item_id,
    cb.i_product_name,
    cb.total_sales,
    cb.total_returns,
    cb.net_sales,
    cb.i_current_price,
    CASE 
        WHEN cb.net_sales > 1000 THEN 'High Performer'
        WHEN cb.net_sales BETWEEN 500 AND 1000 THEN 'Medium Performer'
        ELSE 'Low Performer' 
    END AS performance_category
FROM CombinedResults cb
JOIN customer c ON c.c_current_cdemo_sk IN (SELECT cd_demo_sk FROM customer_demographics WHERE cd_marital_status = 'M' AND cd_gender = 'F')
WHERE cb.total_sales > 0
ORDER BY cb.net_sales DESC
LIMIT 100;
