
WITH RECURSIVE SalesHierarchy AS (
    SELECT ws_item_sk, 
           SUM(ws_quantity) AS total_sold,
           ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_quantity) DESC) AS rank
    FROM web_sales
    GROUP BY ws_item_sk
),
CustomerStats AS (
    SELECT cd_gender, 
           cd_marital_status, 
           AVG(cd_purchase_estimate) AS avg_purchase,
           COUNT(DISTINCT c_customer_sk) AS customer_count
    FROM customer
    JOIN customer_demographics ON c_current_cdemo_sk = cd_demo_sk
    GROUP BY cd_gender, cd_marital_status
),
SalesSummary AS (
    SELECT i_item_id,
           SUM(COALESCE(ss_ext_sales_price, 0)) AS total_sales,
           ROUND(SUM(COALESCE(ss_net_profit, 0)), 2) AS total_profit,
           MAX(ss_sold_date_sk) AS last_sold_date
    FROM store_sales
    LEFT JOIN item ON ss_item_sk = i_item_sk
    GROUP BY i_item_id
),
TopSellingItems AS (
    SELECT s_item.i_item_id, total_sold
    FROM (
        SELECT i_item_sk, SUM(ws_quantity) AS total_sold
        FROM web_sales
        GROUP BY i_item_sk
        ORDER BY total_sold DESC
        LIMIT 10
    ) as s_item
    JOIN item ON s_item.i_item_sk = item.i_item_sk
),
FinalReport AS (
    SELECT tsi.i_item_id,
           ss.total_sales,
           ss.total_profit,
           cs.avg_purchase,
           cs.customer_count
    FROM TopSellingItems tsi
    JOIN SalesSummary ss ON tsi.i_item_id = ss.i_item_id
    LEFT JOIN CustomerStats cs ON 1=1
)
SELECT *
FROM FinalReport
WHERE total_profit > 1000
  AND total_sales IS NOT NULL
ORDER BY total_profit DESC;
