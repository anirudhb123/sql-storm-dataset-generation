
WITH RECURSIVE CustomerHierarchy AS (
    SELECT c_customer_sk, c_customer_id, c_first_name, c_last_name, c_current_cdemo_sk,
           1 AS level
    FROM customer
    WHERE c_customer_sk = (SELECT MAX(cc_call_center_sk) FROM call_center)

    UNION ALL

    SELECT c.c_customer_sk, c.c_customer_id, c.c_first_name, c.c_last_name, c.c_current_cdemo_sk,
           ch.level + 1
    FROM customer c
    JOIN CustomerHierarchy ch ON c.c_current_cdemo_sk = ch.c_current_cdemo_sk
    WHERE ch.level < 5
),

TotalSales AS (
    SELECT ws_bill_customer_sk AS customer_sk, 
           SUM(ws_net_paid_inc_tax) AS total_sales
    FROM web_sales
    GROUP BY ws_bill_customer_sk
),

SalesWithRanks AS (
    SELECT customer_sk, total_sales,
           RANK() OVER (ORDER BY total_sales DESC) AS sales_rank
    FROM TotalSales
),

CustomerInfo AS (
    SELECT c.c_customer_id, c.c_first_name, c.c_last_name, 
           cd.cd_marital_status, cd.cd_gender,
           dh.hd_income_band_sk
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics dh ON cd.cd_demo_sk = dh.hd_demo_sk
)

SELECT ci.c_customer_id, ci.c_first_name, ci.c_last_name, 
       ci.cd_marital_status, ci.cd_gender,
       COALESCE(ts.total_sales, 0) AS total_sales,
       sr.sales_rank
FROM CustomerInfo ci
LEFT JOIN TotalSales ts ON ci.c_customer_id = ts.customer_sk
JOIN SalesWithRanks sr ON ci.c_customer_id = sr.customer_sk
WHERE (ci.cd_marital_status IN ('M', 'S') OR ci.cd_gender = 'F')
  AND (sr.sales_rank <= 10 OR total_sales > 10000)
ORDER BY total_sales DESC, ci.c_last_name
LIMIT 50;
