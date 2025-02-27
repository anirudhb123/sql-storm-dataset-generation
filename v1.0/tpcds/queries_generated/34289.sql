
WITH RECURSIVE ItemHierarchy AS (
    SELECT i_item_sk, i_item_id, i_item_desc, i_current_price, 1 AS level
    FROM item
    WHERE i_item_sk IN (SELECT sr_item_sk FROM store_returns WHERE sr_return_quantity > 0)
    UNION ALL
    SELECT i.i_item_sk, i.i_item_id, i.i_item_desc, i.i_current_price, ih.level + 1
    FROM item i
    JOIN ItemHierarchy ih ON i.i_item_sk = ih.i_item_sk
),
DailySales AS (
    SELECT d.d_date, SUM(ws.ws_ext_sales_price) AS total_sales
    FROM date_dim d
    JOIN web_sales ws ON d.d_date_sk = ws.ws_sold_date_sk
    GROUP BY d.d_date
),
HighReturnItems AS (
    SELECT sr_item_sk, SUM(sr_return_quantity) AS total_returned
    FROM store_returns
    GROUP BY sr_item_sk
    HAVING SUM(sr_return_quantity) > 10
),
CustomerAnalysis AS (
    SELECT cd.cd_demo_sk, cd.cd_gender, cd.cd_marital_status, COUNT(DISTINCT c.c_customer_sk) AS customer_count
    FROM customer_demographics cd
    LEFT JOIN customer c ON cd.cd_demo_sk = c.c_current_cdemo_sk
    GROUP BY cd.cd_demo_sk, cd.cd_gender, cd.cd_marital_status
)
SELECT
    dh.d_date,
    COALESCE(ds.total_sales, 0) AS daily_sales,
    ih.i_item_id,
    ih.i_item_desc,
    ih.level,
    hri.total_returned,
    ca.customer_count,
    ROW_NUMBER() OVER (PARTITION BY dh.d_date ORDER BY ds.total_sales DESC) AS sales_rank
FROM DailySales ds
FULL OUTER JOIN date_dim dh ON ds.d_date = dh.d_date
JOIN ItemHierarchy ih ON ih.i_item_sk IN (SELECT sr_item_sk FROM HighReturnItems hri WHERE hri.total_returned > 10)
LEFT JOIN HighReturnItems hri ON ih.i_item_sk = hri.sr_item_sk
LEFT JOIN CustomerAnalysis ca ON ca.cd_demo_sk IN (SELECT DISTINCT c.c_current_cdemo_sk FROM customer c WHERE c.c_current_cdemo_sk IS NOT NULL)
WHERE (hri.total_returned IS NOT NULL OR ds.total_sales > 0)
ORDER BY dh.d_date, sales_rank;
