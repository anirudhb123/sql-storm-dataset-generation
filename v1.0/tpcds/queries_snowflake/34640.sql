
WITH RECURSIVE customer_hierarchy AS (
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, c.c_preferred_cust_flag, c.c_birth_year, 
           1 AS generation
    FROM customer c
    WHERE c.c_birth_year IS NOT NULL
      AND c.c_birth_year > (SELECT MAX(d_year) FROM date_dim)
    
    UNION ALL
    
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, c.c_preferred_cust_flag, c.c_birth_year,
           ch.generation + 1
    FROM customer_hierarchy ch
    JOIN customer c ON ch.c_customer_sk = c.c_current_hdemo_sk 
    WHERE c.c_birth_year IS NOT NULL
)

SELECT ca.ca_city, 
       COUNT(DISTINCT c.c_customer_sk) AS customer_count,
       SUM(COALESCE(su.ss_ext_sales_price, 0)) AS total_sales,
       AVG(COALESCE(cd.cd_purchase_estimate, 0)) AS avg_purchase_estimate,
       (SELECT COUNT(*)
        FROM store_sales ss
        WHERE ss.ss_sold_date_sk BETWEEN 1000 AND 2000
        AND ss.ss_quantity > 5) AS total_large_sales,
       RANK() OVER (PARTITION BY ca.ca_city ORDER BY COUNT(DISTINCT c.c_customer_sk) DESC) AS city_rank
FROM customer_address ca
LEFT JOIN customer c ON ca.ca_address_sk = c.c_current_addr_sk
LEFT JOIN customer_demographics cd ON cd.cd_demo_sk = c.c_current_cdemo_sk
LEFT JOIN store_sales su ON su.ss_customer_sk = c.c_customer_sk
WHERE ca.ca_country = 'USA'
  AND (c.c_birth_year IS NOT NULL OR c.c_preferred_cust_flag = 'Y')
GROUP BY ca.ca_city
HAVING SUM(COALESCE(su.ss_ext_sales_price, 0)) > 1000
   OR COUNT(DISTINCT c.c_customer_sk) > 10
ORDER BY customer_count DESC;
