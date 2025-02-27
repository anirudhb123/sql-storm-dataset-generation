
WITH RECURSIVE sales_history AS (
    SELECT ss_customer_sk,
           SUM(ss_ext_sales_price) AS total_sales,
           COUNT(ss_ticket_number) AS total_transactions,
           ROW_NUMBER() OVER (PARTITION BY ss_customer_sk ORDER BY SUM(ss_ext_sales_price) DESC) AS rank
    FROM store_sales
    GROUP BY ss_customer_sk
    UNION ALL
    SELECT sh.ss_customer_sk,
           sh.total_sales + COALESCE(ss.total_sales, 0) AS total_sales,
           sh.total_transactions + COALESCE(ss.total_transactions, 0) AS total_transactions,
           ROW_NUMBER() OVER (PARTITION BY sh.ss_customer_sk ORDER BY (sh.total_sales + COALESCE(ss.total_sales, 0)) DESC) AS rank
    FROM sales_history sh
    LEFT JOIN store_sales ss ON ss.ss_customer_sk = sh.ss_customer_sk
    WHERE sh.rank < 5
),
customer_summary AS (
    SELECT c_customer_sk,
           c_first_name,
           c_last_name,
           cd_gender,
           cd_marital_status,
           cd_purchase_estimate,
           COALESCE(cd_dep_count, 0) AS dependents,
           CASE
               WHEN cd_purchase_estimate < 100 THEN 'Low Value'
               WHEN cd_purchase_estimate BETWEEN 100 AND 1000 THEN 'Medium Value'
               ELSE 'High Value'
           END AS customer_value,
           ROW_NUMBER() OVER (ORDER BY cd_purchase_estimate DESC) AS customer_rank
    FROM customer
    LEFT JOIN customer_demographics ON c_current_cdemo_sk = cd_demo_sk
),
return_summary AS (
    SELECT sr_customer_sk,
           SUM(sr_return_amt_inc_tax) AS total_return_amount,
           COUNT(sr_ticket_number) AS return_count
    FROM store_returns
    GROUP BY sr_customer_sk
)
SELECT cs.c_customer_sk,
       cs.c_first_name,
       cs.c_last_name,
       cs.customer_value,
       COALESCE(sh.total_sales, 0) AS total_sales,
       COALESCE(rs.total_return_amount, 0) AS total_return_amount,
       CASE
           WHEN sh.total_sales IS NULL THEN 'No Sales'
           WHEN rs.total_return_amount IS NULL THEN 'No Returns'
           ELSE 'Has Transactions'
       END AS transaction_status
FROM customer_summary cs
LEFT JOIN sales_history sh ON cs.c_customer_sk = sh.ss_customer_sk
LEFT JOIN return_summary rs ON cs.c_customer_sk = rs.sr_customer_sk
WHERE cs.customer_rank <= 100
ORDER BY cs.customer_value DESC, sh.total_sales DESC;
