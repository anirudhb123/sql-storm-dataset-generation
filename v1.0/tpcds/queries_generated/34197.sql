
WITH RECURSIVE SalesHierarchy AS (
    SELECT 
        cs.customer_sk,
        cs.total_sales,
        0 AS level
    FROM (
        SELECT 
            ss.ss_customer_sk AS customer_sk,
            SUM(ss.ss_sales_price * ss.ss_quantity) AS total_sales
        FROM 
            store_sales ss
        WHERE 
            ss.ss_sold_date_sk BETWEEN 20200101 AND 20201231
        GROUP BY 
            ss.ss_customer_sk
    ) cs

    UNION ALL

    SELECT 
        ch.customer_sk,
        ch.total_sales,
        level + 1
    FROM 
        SalesHierarchy sh
    JOIN 
        customer_demographics cd ON cd.cd_demo_sk = sh.customer_sk
    JOIN 
        household_demographics hd ON hd.hd_demo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON ca.ca_address_sk = customer.c_current_addr_sk
    JOIN 
        customer c ON c.c_customer_sk = cd.cd_demo_sk
    WHERE 
        sh.total_sales > 5000 AND level < 3
)
SELECT 
    c.c_customer_id,
    SUM(sh.total_sales) AS total_sales,
    COUNT(DISTINCT CASE WHEN ca.ca_city IS NOT NULL THEN ca.ca_city END) AS unique_cities,
    MAX(COALESCE(cd.cd_purchase_estimate, 0)) AS max_purchase_estimate,
    STRING_AGG(DISTINCT ca.ca_state, ', ') AS states,
    ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY SUM(sh.total_sales) DESC) AS sales_rank
FROM 
    SalesHierarchy sh
JOIN 
    customer c ON sh.customer_sk = c.c_customer_sk
JOIN 
    customer_demographics cd ON cd.cd_demo_sk = c.c_current_cdemo_sk
JOIN 
    customer_address ca ON ca.ca_address_sk = c.c_current_addr_sk
GROUP BY 
    c.c_customer_id
HAVING 
    total_sales > 10000
ORDER BY 
    total_sales DESC
LIMIT 10;
