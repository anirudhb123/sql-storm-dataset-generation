
WITH RECURSIVE SalesHierarchy AS (
    SELECT c_customer_sk, 
           c_first_name, 
           c_last_name, 
           0 AS Level
    FROM customer
    WHERE c_customer_sk IS NOT NULL
    UNION ALL
    SELECT s.ss_customer_sk, 
           sh.c_first_name, 
           sh.c_last_name, 
           Level + 1
    FROM store_sales AS s
    JOIN SalesHierarchy AS sh ON s.ss_customer_sk = sh.c_customer_sk
    WHERE s.ss_quantity > 10
), SalesAggregates AS (
    SELECT 
        sh.c_customer_sk,
        sh.c_first_name,
        sh.c_last_name,
        COUNT(ss_ticket_number) AS total_sales,
        SUM(ss_sales_price) AS total_revenue,
        AVG(ss_quantity) AS avg_quantity
    FROM store_sales AS s
    JOIN SalesHierarchy AS sh ON s.ss_customer_sk = sh.c_customer_sk
    GROUP BY sh.c_customer_sk, sh.c_first_name, sh.c_last_name
), CustomersWithDemographics AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        sa.total_sales,
        sa.total_revenue,
        sa.avg_quantity
    FROM customer AS c
    LEFT JOIN customer_demographics AS cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN SalesAggregates AS sa ON c.c_customer_sk = sa.c_customer_sk
    WHERE (cd.cd_gender = 'F' OR cd.cd_marital_status = 'M') 
    AND sa.total_sales > 5
)
SELECT 
    ca.ca_city,
    COUNT(DISTINCT c.c_customer_sk) AS number_of_customers,
    SUM(cwd.total_revenue) AS total_revenue,
    AVG(cwd.avg_quantity) AS avg_quantity_per_customer
FROM CustomersWithDemographics AS cwd
JOIN customer_address AS ca ON cwd.c_customer_sk = ca.ca_address_sk
GROUP BY ca.ca_city
HAVING SUM(cwd.total_revenue) > 10000
ORDER BY total_revenue DESC
LIMIT 10;
