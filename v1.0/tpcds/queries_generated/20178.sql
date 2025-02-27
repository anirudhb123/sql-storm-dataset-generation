
WITH RECURSIVE sales_cte AS (
    SELECT ws_item_sk, 
           SUM(ws_quantity) AS total_sales,
           SUM(ws_net_profit) AS total_profit,
           ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_net_profit) DESC) AS item_rank
    FROM web_sales 
    WHERE ws_sold_date_sk IN (SELECT d_date_sk 
                               FROM date_dim 
                               WHERE d_year = 2023)
    GROUP BY ws_item_sk
), 
customer_info AS (
    SELECT c.c_customer_sk, 
           cd.cd_gender,
           CASE 
               WHEN cd.cd_marital_status = 'M' THEN 'Married'
               WHEN cd.cd_marital_status = 'S' THEN 'Single'
               ELSE 'Other'
           END AS marital_status,
           cd.cd_credit_rating,
           cd.credit_rating,
           ROW_NUMBER() OVER (PARTITION BY cd_credit_rating ORDER BY c.c_customer_sk) AS credit_rank
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE cd.cd_purchase_estimate IS NOT NULL
)
SELECT ci.c_customer_sk,
       MAX(ci.cd_gender) AS gender,
       AVG(CASE 
               WHEN si.total_sales IS NULL THEN 0 
               ELSE si.total_sales 
           END) AS avg_sales,
       SUM(ci.marital_status = 'Married') as count_married,
       COALESCE((SELECT COUNT(*)
                 FROM store_sales ss
                 WHERE ss.ss_customer_sk = ci.c_customer_sk 
                   AND ss.ss_sold_date_sk IN (SELECT d_date_sk 
                                               FROM date_dim 
                                               WHERE d_year = 2023)
                GROUP BY ss.ss_customer_sk), 0) AS store_sales_count,
       CASE 
           WHEN AVG(si.total_sales) > 1000 THEN 'High Value'
           WHEN AVG(si.total_sales) BETWEEN 500 AND 1000 THEN 'Medium Value'
           ELSE 'Low Value'
       END AS customer_value
FROM customer_info ci
LEFT JOIN sales_cte si ON si.ws_item_sk IN (SELECT ws_item_sk 
                                             FROM web_sales
                                             WHERE ws_billed_customer_sk = ci.c_customer_sk)
GROUP BY ci.c_customer_sk
HAVING SUM(si.total_profit) IS NOT NULL 
   AND MAX(si.total_profit) > 0 
   AND MIN(ci.credit_rank) IS NOT NULL
ORDER BY customer_value DESC, count_married DESC, avg_sales DESC
OFFSET 5 ROWS FETCH NEXT 10 ROWS ONLY;
