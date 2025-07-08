
WITH RECURSIVE CustomerHierarchy AS (
    SELECT c.c_customer_sk, 
           c.c_first_name, 
           c.c_last_name, 
           cd.cd_marital_status, 
           cd.cd_gender, 
           0 AS depth
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE c.c_customer_sk = (SELECT MIN(c_customer_sk) FROM customer)
    
    UNION ALL
    
    SELECT c.c_customer_sk, 
           c.c_first_name, 
           c.c_last_name, 
           cd.cd_marital_status, 
           cd.cd_gender, 
           ch.depth + 1
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN CustomerHierarchy ch ON ch.c_customer_sk = c.c_current_addr_sk
),
AggReturns AS (
    SELECT sr_customer_sk,
           COUNT(sr_item_sk) AS return_count,
           SUM(sr_return_amt) AS total_return_amt
    FROM store_returns
    GROUP BY sr_customer_sk
),
SalesData AS (
    SELECT ws_bill_customer_sk AS customer_sk,
           SUM(ws_ext_sales_price) AS total_sales,
           MIN(d.d_date) AS first_purchase_date,
           MAX(d.d_date) AS last_purchase_date
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    GROUP BY ws_bill_customer_sk
)
SELECT ch.c_first_name, 
       ch.c_last_name, 
       ch.cd_marital_status, 
       ch.cd_gender, 
       COALESCE(sd.total_sales, 0) AS total_sales,
       COALESCE(ar.return_count, 0) AS return_count,
       COALESCE(ar.total_return_amt, 0) AS total_return_amt,
       DATE_PART('year', CURRENT_DATE) - DATE_PART('year', MIN(sd.first_purchase_date)) AS customer_age
FROM CustomerHierarchy ch
LEFT JOIN SalesData sd ON ch.c_customer_sk = sd.customer_sk
LEFT JOIN AggReturns ar ON ch.c_customer_sk = ar.sr_customer_sk
GROUP BY ch.c_first_name, ch.c_last_name, ch.cd_marital_status, ch.cd_gender, sd.total_sales, ar.return_count, ar.total_return_amt
HAVING SUM(sd.total_sales) - SUM(ar.total_return_amt) > 1000
ORDER BY customer_age DESC, total_sales DESC
LIMIT 100;
