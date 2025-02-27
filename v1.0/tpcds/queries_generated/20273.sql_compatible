
WITH RecursiveAddress AS (
    SELECT ca_address_sk, ca_city, ca_state, ca_country, 
           ROW_NUMBER() OVER (PARTITION BY ca_city ORDER BY ca_address_sk) AS rn
    FROM customer_address 
    WHERE ca_country = 'USA'
), 
CustomerWithAddress AS (
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, 
           MAX(ca.ca_city) AS city 
    FROM customer c 
    LEFT JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk 
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name
), 
SalesSummary AS (
    SELECT ws_bill_customer_sk, 
           SUM(ws_ext_sales_price) AS total_sales, 
           COUNT(*) AS total_orders
    FROM web_sales 
    WHERE ws_sold_date_sk BETWEEN 1 AND 31 
    GROUP BY ws_bill_customer_sk
),
FinalMetrics AS (
    SELECT cwa.c_customer_sk, cwa.c_first_name, cwa.c_last_name, 
           COALESCE(ss.total_sales, 0) AS total_sales, 
           CASE 
               WHEN COALESCE(ss.total_orders, 0) = 0 THEN NULL 
               ELSE COALESCE(ss.total_sales, 0) / COALESCE(ss.total_orders, 1) 
           END AS avg_order_value,
           ra.ca_city, ra.ca_state, ra.ca_country
    FROM CustomerWithAddress cwa
    LEFT JOIN SalesSummary ss ON cwa.c_customer_sk = ss.ws_bill_customer_sk 
    LEFT JOIN RecursiveAddress ra ON ra.rn = 1 AND ra.ca_city = cwa.city
),
RankedCustomers AS (
    SELECT f.*, 
           RANK() OVER (PARTITION BY f.ca_city ORDER BY f.total_sales DESC) AS city_rank
    FROM FinalMetrics f
)
SELECT f.*, 
       CASE 
           WHEN total_sales > 5000 THEN 'High Value'
           WHEN total_sales BETWEEN 1000 AND 5000 THEN 'Medium Value'
           ELSE 'Low Value' 
       END AS customer_value_segment
FROM RankedCustomers f
WHERE (f.ca_state IS NOT NULL OR f.ca_country IS NULL)
  AND (f.total_sales IS NOT NULL OR f.total_orders = 0) 
ORDER BY f.ca_city, customer_value_segment DESC, f.total_sales DESC;
