
WITH RECURSIVE CustomerHierarchy AS (
    SELECT c.c_customer_sk,
           c.c_first_name,
           c.c_last_name,
           c.c_birth_day,
           c.c_birth_month,
           c.c_birth_year,
           0 AS level
    FROM customer c
    WHERE c.c_birth_year IS NOT NULL AND c.c_birth_month IS NOT NULL
    UNION ALL
    SELECT ch.c_customer_sk,
           ch.c_first_name,
           ch.c_last_name,
           ch.c_birth_day,
           ch.c_birth_month,
           ch.c_birth_year,
           ch.level + 1
    FROM customer c
    JOIN CustomerHierarchy ch ON c.c_current_cdemo_sk = ch.c_customer_sk
    WHERE c.c_birth_year IS NOT NULL AND c.c_birth_month IS NOT NULL
),
ItemSales AS (
    SELECT ws.ws_item_sk,
           SUM(ws.ws_quantity) AS total_quantity,
           SUM(ws.ws_sales_price * ws.ws_quantity) AS total_sales
    FROM web_sales ws
    GROUP BY ws.ws_item_sk
),
TopItems AS (
    SELECT i.i_item_id,
           i.i_item_desc,
           is.total_quantity,
           is.total_sales,
           RANK() OVER (ORDER BY is.total_sales DESC) AS sales_rank
    FROM item i
    JOIN ItemSales is ON i.i_item_sk = is.ws_item_sk
),
Returns AS (
    SELECT sr_item_sk,
           SUM(sr_return_quantity) AS total_returns
    FROM store_returns
    GROUP BY sr_item_sk
),
FinalReport AS (
    SELECT c.c_customer_sk,
           CONCAT(c.c_first_name, ' ', c.c_last_name) AS customer_name,
           th.c_item_id,
           th.c_item_desc,
           COALESCE(ir.total_returns, 0) AS total_returns,
           th.total_quantity,
           th.total_sales,
           CASE 
               WHEN th.total_sales > 1000 THEN 'High Value'
               WHEN th.total_sales BETWEEN 500 AND 1000 THEN 'Medium Value'
               ELSE 'Low Value'
           END AS value_category
    FROM CustomerHierarchy c
    LEFT JOIN TopItems th ON c.c_customer_sk = th.c_customer_sk
    LEFT JOIN Returns ir ON th.ws_item_sk = ir.sr_item_sk
)
SELECT fr.customer_name,
       fr.c_item_id,
       fr.total_quantity,
       fr.total_sales,
       fr.total_returns,
       fr.value_category
FROM FinalReport fr
WHERE fr.total_sales IS NOT NULL
  AND fr.total_quantity > (
      SELECT AVG(total_quantity)
      FROM FinalReport
  ) 
ORDER BY fr.total_sales DESC
LIMIT 100;
