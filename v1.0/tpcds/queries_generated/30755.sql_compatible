
WITH RECURSIVE AddressHierarchy AS (
    SELECT ca_address_sk, ca_city, ca_state, ca_zip, 0 AS level
    FROM customer_address
    WHERE ca_state = 'CA'
    
    UNION ALL
    
    SELECT ca.ca_address_sk, CONCAT(ca.ca_city, ' - Sub') AS ca_city, ca.ca_state, ca.ca_zip, ah.level + 1
    FROM customer_address ca
    INNER JOIN AddressHierarchy ah ON ca.ca_address_sk = ah.ca_address_sk + 1
    WHERE ah.level < 5
),
CustomerDemographics AS (
    SELECT cd_gender, cd_marital_status, COUNT(c.c_customer_sk) AS customer_count,
           AVG(cd_dep_count) AS average_dependents
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY cd_gender, cd_marital_status
),
DailySales AS (
    SELECT d.d_date, SUM(ws.ws_sales_price) AS total_sales,
           COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM date_dim d
    LEFT JOIN web_sales ws ON d.d_date_sk = ws.ws_sold_date_sk
    GROUP BY d.d_date
),
SalesWithAnalytics AS (
    SELECT d.d_date, total_sales, order_count,
           RANK() OVER (ORDER BY total_sales DESC) AS sales_rank,
           LAG(total_sales) OVER (ORDER BY d.d_date) AS previous_sales
    FROM DailySales d
)
SELECT ah.ca_city, ah.ca_zip, cd.cd_gender, cd.cd_marital_status,
       sa.d_date, sa.total_sales, sa.sales_rank,
       CASE 
           WHEN sa.total_sales IS NULL THEN 'No Sales'
           WHEN sa.previous_sales IS NULL THEN 'First Sale'
           ELSE CASE 
               WHEN sa.total_sales > sa.previous_sales THEN 'Increase'
               ELSE 'Decrease' 
           END 
       END AS sales_status
FROM AddressHierarchy ah
CROSS JOIN CustomerDemographics cd
LEFT JOIN SalesWithAnalytics sa ON ah.ca_zip = LEFT(CAST(sa.d_date AS VARCHAR), 5)
WHERE cd.customer_count > 10
ORDER BY ah.ca_city, sa.d_date DESC;
