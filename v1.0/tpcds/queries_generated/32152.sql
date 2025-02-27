
WITH RECURSIVE sales_hierarchy AS (
    SELECT c.c_customer_sk,
           c.c_first_name,
           c.c_last_name,
           COALESCE(s.sum_sales, 0) AS total_sales,
           1 AS level
    FROM customer AS c
    LEFT JOIN (
        SELECT ws_bill_customer_sk,
               SUM(ws_net_paid_inc_tax) AS sum_sales
        FROM web_sales
        GROUP BY ws_bill_customer_sk
    ) AS s ON c.c_customer_sk = s.ws_bill_customer_sk
    
    UNION ALL
    
    SELECT h.hd_demo_sk,
           'Unknown' AS c_first_name,
           'Unknown' AS c_last_name,
           COALESCE(s.sum_sales, 0) AS total_sales,
           level + 1
    FROM household_demographics AS h
    LEFT JOIN (
        SELECT cs_bill_customer_sk,
               SUM(cs_net_paid_inc_tax) AS sum_sales
        FROM catalog_sales
        GROUP BY cs_bill_customer_sk
    ) AS s ON h.hd_demo_sk = s.cs_bill_customer_sk
    WHERE level < 3
)
SELECT DATE_FORMAT(DATE_ADD(CURDATE(), INTERVAL level DAY), '%Y-%m-%d') AS sales_date,
       SUM(total_sales) AS total_sales_amount,
       COUNT(c_customer_sk) AS total_customers
FROM sales_hierarchy
WHERE total_sales > 1000
GROUP BY sales_date
ORDER BY sales_date DESC
LIMIT 10;

SELECT DISTINCT c.c_first_name,
                c.c_last_name,
                COALESCE(NULLIF(c.c_email_address, ''), 'No Email') AS email,
                CASE WHEN cd.marital_status = 'M' THEN 'Married'
                     WHEN cd.marital_status = 'S' THEN 'Single'
                     ELSE 'Other' END AS marital_status
FROM customer AS c
LEFT JOIN customer_demographics AS cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
WHERE cd.education_status IN ('PhD', 'Masters')
  AND c.c_birth_year IS NOT NULL
  AND YEAR(CURDATE()) - c.c_birth_year > 30
ORDER BY c.c_last_name, c.c_first_name;
