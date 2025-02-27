
WITH RECURSIVE CustomerHierarchy AS (
    SELECT c.c_customer_sk, c.c_customer_id, c.c_first_name, c.c_last_name, 
           cd.cd_gender, cd.cd_marital_status, cd.cd_purchase_estimate,
           1 AS Level
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE cd.cd_gender = 'F'
    UNION ALL
    SELECT c.c_customer_sk, c.c_customer_id, c.c_first_name, c.c_last_name, 
           cd.cd_gender, cd.cd_marital_status, cd.cd_purchase_estimate,
           ch.Level + 1
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN CustomerHierarchy ch ON c.c_current_cdemo_sk = ch.c_customer_sk
    WHERE cd.cd_marital_status = 'S' AND ch.Level < 5
),
TotalReturns AS (
    SELECT sr_customer_sk, SUM(sr_return_quantity) AS total_return_quantity,
           SUM(sr_return_amt) AS total_return_amt, 
           COUNT(DISTINCT sr_ticket_number) AS return_count
    FROM store_returns
    GROUP BY sr_customer_sk
),
AggregateSales AS (
    SELECT ws_bill_customer_sk, SUM(ws_ext_sales_price) AS total_sales,
           COUNT(DISTINCT ws_order_number) AS sales_count
    FROM web_sales
    GROUP BY ws_bill_customer_sk
),
RankedReturns AS (
    SELECT ch.c_customer_id, ch.c_first_name, ch.c_last_name, 
           COALESCE(tr.total_return_quantity, 0) AS total_return_quantity,
           COALESCE(tr.total_return_amt, 0) AS total_return_amt,
           ar.total_sales, ar.sales_count, 
           DENSE_RANK() OVER (PARTITION BY ch.cd_gender ORDER BY COALESCE(ar.total_sales, 0) DESC) as sales_rank
    FROM CustomerHierarchy ch
    LEFT JOIN TotalReturns tr ON ch.c_customer_sk = tr.sr_customer_sk
    LEFT JOIN AggregateSales ar ON ch.c_customer_sk = ar.ws_bill_customer_sk
)
SELECT r.c_customer_id, r.c_first_name, r.c_last_name, r.total_return_quantity, 
       r.total_return_amt, r.total_sales, r.sales_count,
       CASE 
           WHEN r.total_sales > 1000 THEN 'High Roller'
           WHEN r.total_sales BETWEEN 500 AND 1000 THEN 'Mid-tier'
           WHEN r.total_sales < 500 THEN 'Low-tier'
           ELSE 'No Sales'
       END AS customer_tier,
       CASE 
           WHEN r.total_return_quantity IS NULL THEN 'No Returns'
           WHEN r.total_return_quantity >= 1 THEN 'Frequent Returner'
           ELSE 'Rare Returner'
       END AS return_behavior,
       COALESCE(NULLIF(NULL, ''), 'Default String') AS obscure_case,
       CASE 
           WHEN r.sales_rank IS NULL THEN 'Rank Not Available'
           ELSE CONCAT('Rank: ', r.sales_rank)
       END AS ranking_status
FROM RankedReturns r
WHERE r.total_sales > 0 OR r.total_return_quantity > 0
ORDER BY r.total_sales DESC, r.total_return_quantity ASC;
