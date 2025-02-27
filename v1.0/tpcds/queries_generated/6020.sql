
WITH CustomerSales AS (
    SELECT c.c_customer_id, 
           SUM(ws.ws_ext_sales_price) AS total_sales, 
           COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM customer c
    JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE ws.ws_sold_date_sk BETWEEN 2458965 AND 2459250  -- example date range
    GROUP BY c.c_customer_id
), CustomerDemographics AS (
    SELECT cd.cd_demo_sk, 
           cd.cd_gender, 
           cd.cd_marital_status, 
           cd.cd_education_status
    FROM customer_demographics cd
    JOIN customer c ON cd.cd_demo_sk = c.c_current_cdemo_sk
), SalesWithDemographics AS (
    SELECT cs.c_customer_id, 
           cs.total_sales, 
           cs.order_count, 
           cd.cd_gender, 
           cd.cd_marital_status, 
           cd.cd_education_status
    FROM CustomerSales cs
    JOIN CustomerDemographics cd ON cs.c_customer_id = c.c_customer_id
), FilteredSales AS (
    SELECT swd.*, 
           CASE 
               WHEN swd.total_sales > 1000 THEN 'High Value'
               WHEN swd.total_sales BETWEEN 500 AND 1000 THEN 'Medium Value'
               ELSE 'Low Value' 
           END AS customer_value_category
    FROM SalesWithDemographics swd
)
SELECT fsc.customer_value_category, 
       COUNT(*) AS customer_count, 
       AVG(fsc.total_sales) AS average_sales, 
       AVG(fsc.order_count) AS average_orders
FROM FilteredSales fsc
GROUP BY fsc.customer_value_category
ORDER BY customer_count DESC;
