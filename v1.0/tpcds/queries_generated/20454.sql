
WITH RecursiveStoreSales AS (
    SELECT ss_store_sk, 
           ss_sold_date_sk, 
           SUM(ss_quantity) AS total_sales,
           ROW_NUMBER() OVER(PARTITION BY ss_store_sk ORDER BY ss_sold_date_sk DESC) AS sales_rank
    FROM store_sales
    GROUP BY ss_store_sk, ss_sold_date_sk
), 
CustomerAggregate AS (
    SELECT c.c_customer_sk,
           COUNT(DISTINCT cr.returning_customer_sk) AS return_count,
           MAX(cd.cd_credit_rating) AS best_credit_rating,
           SUM(CASE 
                   WHEN cd.cd_marital_status = 'M' THEN 1 
                   ELSE 0 
               END) AS married_customers
    FROM customer c
    LEFT JOIN store_returns cr ON c.c_customer_sk = cr.s_returning_customer_sk
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY c.c_customer_sk
), 
SalesWithReturnInfo AS (
    SELECT ss.ss_store_sk,
           ss.ss_sold_date_sk,
           ss.ss_customer_sk,
           COALESCE(ca.return_count, 0) AS return_count,
           RANK() OVER (PARTITION BY ss.ss_store_sk ORDER BY ss.ss_list_price DESC) AS price_rank
    FROM store_sales ss
    LEFT JOIN CustomerAggregate ca ON ss.ss_customer_sk = ca.c_customer_sk
)
SELECT ssw.ss_store_sk,
       COUNT(*) AS order_count,
       AVG(ssw.ss_sales_price) AS avg_sales_price,
       COUNT(DISTINCT CASE WHEN s.return_count > 0 THEN s.ss_customer_sk END) AS unique_return_customers,
       SUM(CASE WHEN (ssw.ss_list_price > 100 AND s.return_count = 0) THEN 1 ELSE 0 END) AS high_value_non_return_orders,
       CASE 
           WHEN AVG(ssw.ss_sales_price) > (SELECT AVG(ss_sales_price) FROM store_sales) THEN 'Above Average'
           ELSE 'Below Average'
       END AS sales_performance
FROM SalesWithReturnInfo ssw
INNER JOIN RecursiveStoreSales rss ON ssw.ss_store_sk = rss.ss_store_sk
WHERE ssw.price_rank = 1
AND (rss.sales_rank <= 5 OR ssw.ss_customer_sk IS NULL)
GROUP BY ssw.ss_store_sk
ORDER BY order_count DESC
LIMIT 100;
