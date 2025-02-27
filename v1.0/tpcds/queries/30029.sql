
WITH RECURSIVE CustomerHierarchy AS (
    SELECT c.c_customer_sk, c.c_customer_id, c.c_first_name, c.c_last_name, c.c_salutation,
           cd.cd_gender, cd.cd_marital_status, cd.cd_purchase_estimate,
           1 AS level
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE cd.cd_gender = 'F'
    
    UNION ALL
    
    SELECT c.c_customer_sk, c.c_customer_id, c.c_first_name, c.c_last_name, c.c_salutation,
           cd.cd_gender, cd.cd_marital_status, cd.cd_purchase_estimate,
           ch.level + 1
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN CustomerHierarchy ch ON c.c_current_hdemo_sk = ch.c_customer_sk
    WHERE ch.level < 3
),
RankedSales AS (
    SELECT ws.ws_bill_customer_sk, SUM(ws.ws_ext_sales_price) AS total_sales,
           DENSE_RANK() OVER (PARTITION BY ws.ws_bill_customer_sk ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS sales_rank
    FROM web_sales ws
    WHERE ws.ws_sold_date_sk BETWEEN 2462200 AND 2462260
    GROUP BY ws.ws_bill_customer_sk
),
SalesWithDetails AS (
    SELECT ch.c_customer_id, ch.c_first_name, ch.c_last_name, ch.cd_gender, ch.cd_marital_status,
           r.total_sales, r.sales_rank
    FROM CustomerHierarchy ch
    LEFT JOIN RankedSales r ON ch.c_customer_sk = r.ws_bill_customer_sk
)
SELECT s.c_customer_id, s.c_first_name, s.c_last_name, s.cd_gender, s.cd_marital_status,
       COALESCE(s.total_sales, 0) AS total_sales, 
       CASE 
           WHEN s.sales_rank IS NULL THEN 'No Sales'
           WHEN s.total_sales > 1000 THEN 'High Value Customer'
           WHEN s.total_sales BETWEEN 500 AND 1000 THEN 'Medium Value Customer'
           ELSE 'Low Value Customer'
       END AS customer_value
FROM SalesWithDetails s
ORDER BY s.total_sales DESC
LIMIT 50;

