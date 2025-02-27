
WITH CustomerSales AS (
    SELECT c.c_customer_sk,
           c.c_first_name,
           c.c_last_name,
           SUM(ws.ws_ext_sales_price) AS total_sales,
           COUNT(ws.ws_order_number) AS order_count,
           ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS sales_rank
    FROM customer c
    JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name
), HighValueCustomers AS (
    SELECT c.customer_sk, 
           cd.cd_gender,
           cd.cd_marital_status,
           cu.total_sales,
           cu.order_count 
    FROM CustomerSales cu
    JOIN customer_demographics cd ON cu.c_customer_sk = cd.cd_demo_sk
    WHERE cu.total_sales > (SELECT AVG(total_sales) FROM CustomerSales)
), ReturnDetails AS (
    SELECT cr.cr_returning_customer_sk,
           SUM(cr.cr_return_amount) AS total_returned,
           COUNT(cr.cr_order_number) AS return_count
    FROM catalog_returns cr
    GROUP BY cr.cr_returning_customer_sk
), ReturnRisk AS (
    SELECT hvc.customer_sk,
           hvc.total_sales,
           hvc.order_count,
           COALESCE(rd.total_returned, 0) AS total_returned,
           COALESCE(rd.return_count, 0) AS return_count,
           CASE 
               WHEN hvc.total_sales * 0.10 < COALESCE(rd.total_returned, 0) THEN 'High Risk'
               ELSE 'Low Risk' 
           END AS return_risk
    FROM HighValueCustomers hvc
    LEFT JOIN ReturnDetails rd ON hvc.customer_sk = rd.cr_returning_customer_sk
)
SELECT r.customer_sk,
       r.total_sales,
       r.order_count,
       r.total_returned,
       r.return_count,
       r.return_risk,
       CONCAT(r.total_sales, ' USD') AS sales_formatted
FROM ReturnRisk r
WHERE r.return_risk = 'High Risk'
ORDER BY r.total_sales DESC
LIMIT 10;
