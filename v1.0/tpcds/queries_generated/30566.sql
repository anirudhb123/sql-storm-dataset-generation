
WITH RECURSIVE CustomerHierarchy AS (
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status,
           cd.cd_purchase_estimate, cd.cd_dep_count, cd.cd_dep_employed_count, 
           cd.cd_dep_college_count, 0 AS level
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE cd.cd_marital_status = 'M'
    UNION ALL
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status,
           cd.cd_purchase_estimate, cd.cd_dep_count, cd.cd_dep_employed_count, 
           cd.cd_dep_college_count, ch.level + 1
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN CustomerHierarchy ch ON ch.c_customer_sk = c.c_customer_sk
    WHERE cd.cd_marital_status = 'S'
),
SalesData AS (
    SELECT ws.ws_sold_date_sk, SUM(ws.ws_ext_sales_price) AS total_sales,
           COUNT(DISTINCT ws.ws_order_number) AS order_count,
           ROW_NUMBER() OVER (PARTITION BY ws.ws_sold_date_sk ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS sales_rank 
    FROM web_sales ws
    GROUP BY ws.ws_sold_date_sk
),
TopSales AS (
    SELECT sd.ws_sold_date_sk, sd.total_sales, sd.order_count
    FROM SalesData sd
    WHERE sd.sales_rank <= 10
),
CustomerReturns AS (
    SELECT cr.returning_customer_sk, SUM(cr.cr_return_amount) AS total_returns
    FROM catalog_returns cr
    GROUP BY cr.returning_customer_sk
),
FinalReport AS (
    SELECT ch.c_first_name, ch.c_last_name, ch.cd_gender, ch.level,
           COALESCE(tr.total_returns, 0) AS total_returns,
           ts.total_sales, ts.order_count
    FROM CustomerHierarchy ch
    LEFT JOIN CustomerReturns tr ON ch.c_customer_sk = tr.returning_customer_sk
    LEFT JOIN TopSales ts ON ts.ws_sold_date_sk = (SELECT MAX(d.d_date_sk) FROM date_dim d)
)
SELECT f.c_first_name, f.c_last_name, f.cd_gender, f.level, 
       f.total_returns, f.total_sales, f.order_count,
       CASE 
           WHEN f.total_sales > 1000 THEN 'High Value Customer'
           WHEN f.total_sales BETWEEN 500 AND 1000 THEN 'Medium Value Customer'
           ELSE 'Low Value Customer' 
       END AS customer_segment
FROM FinalReport f
WHERE f.total_sales IS NOT NULL OR f.total_returns IS NOT NULL
ORDER BY f.total_sales DESC, f.total_returns DESC;
