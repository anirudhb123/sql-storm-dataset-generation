
WITH RECURSIVE SalesHierarchy AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ss.ss_net_paid) AS total_sales,
        1 AS level,
        CAST(c.c_first_name || ' ' || c.c_last_name AS VARCHAR(100)) AS full_name
    FROM 
        customer c
    JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
    HAVING 
        SUM(ss.ss_net_paid) > 10000

    UNION ALL

    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        sh.total_sales + SUM(ss.ss_net_paid) AS total_sales,
        sh.level + 1,
        CAST(sh.full_name || ' -> ' || c.c_first_name || ' ' || c.c_last_name AS VARCHAR(100)) AS full_name
    FROM 
        SalesHierarchy sh
    JOIN 
        store_sales ss ON ss.ss_customer_sk = sh.c_customer_sk
    JOIN 
        customer c ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, sh.total_sales, sh.level, sh.full_name
    HAVING 
        SUM(ss.ss_net_paid) > 5000
)
SELECT 
    sh.full_name,
    sh.total_sales,
    DENSE_RANK() OVER (ORDER BY sh.total_sales DESC) AS sales_rank
FROM 
    SalesHierarchy sh
WHERE 
    sh.total_sales IS NOT NULL
ORDER BY 
    sh.total_sales DESC;

WITH AddressCounts AS (
    SELECT 
        ca.ca_country,
        COUNT(DISTINCT c.c_customer_sk) AS customer_count
    FROM 
        customer_address ca
    LEFT JOIN 
        customer c ON c.c_current_addr_sk = ca.ca_address_sk
    GROUP BY 
        ca.ca_country
),
CustomerDemographics AS (
    SELECT 
        cd.cd_gender,
        SUM(c.cd_demo_sk IS NOT NULL) AS gender_count
    FROM 
        customer_demographics cd
    LEFT JOIN 
        customer c ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        cd.cd_gender
)
SELECT 
    ac.ca_country,
    ac.customer_count,
    cd.cd_gender,
    cd.gender_count
FROM 
    AddressCounts ac
FULL OUTER JOIN 
    CustomerDemographics cd ON ac.customer_count = cd.gender_count
WHERE 
    (ac.customer_count > 100 OR cd.gender_count IS NULL)
ORDER BY 
    ac.ca_country;
