
WITH CustomerOrders AS (
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, SUM(ss_ext_sales_price) AS total_sales
    FROM customer c
    JOIN store_sales s ON c.c_customer_sk = s.ss_customer_sk
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name
),
HighValueCustomers AS (
    SELECT c.customer_sk, c.first_name, c.last_name, co.total_sales
    FROM CustomerOrders co
    JOIN customer_demographics cd ON co.c_customer_sk = cd.cd_demo_sk
    WHERE co.total_sales > 1000 AND cd.cd_credit_rating = 'Excellent'
),
SalesDistribution AS (
    SELECT h.first_name, h.last_name, h.total_sales,
           CASE 
               WHEN h.total_sales <= 2000 THEN '2000 or less'
               WHEN h.total_sales <= 5000 THEN '2001 to 5000'
               ELSE 'More than 5000'
           END AS sales_band
    FROM HighValueCustomers h
)
SELECT sd.sales_band, COUNT(sd.first_name) AS customer_count
FROM SalesDistribution sd
GROUP BY sd.sales_band
ORDER BY sd.sales_band;
