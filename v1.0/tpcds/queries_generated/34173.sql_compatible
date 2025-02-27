
WITH RECURSIVE SalesHierarchy AS (
    SELECT 
        ss_store_sk,
        SUM(ss_ext_sales_price) AS total_sales,
        COUNT(ss_ticket_number) AS transaction_count,
        1 AS level
    FROM 
        store_sales
    GROUP BY 
        ss_store_sk
    UNION ALL
    SELECT 
        ss.ss_store_sk,
        SUM(ss.ss_ext_sales_price) + sh.total_sales AS total_sales,
        COUNT(ss.ss_ticket_number) + sh.transaction_count AS transaction_count,
        sh.level + 1 AS level
    FROM 
        store_sales ss
    JOIN 
        SalesHierarchy sh ON ss.ss_store_sk = sh.ss_store_sk
    WHERE 
        sh.level < 5
    GROUP BY 
        ss.ss_store_sk, sh.total_sales, sh.transaction_count, sh.level
),
CustomerRevenue AS (
    SELECT
        c.c_customer_sk,
        COALESCE(SUM(ws.ws_ext_sales_price), 0) AS total_web_revenue,
        COALESCE(SUM(ss.ss_ext_sales_price), 0) AS total_store_revenue
    FROM
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY 
        c.c_customer_sk
),
MaxDemo AS (
    SELECT 
        cd_demo_sk,
        MAX(cd_purchase_estimate) AS max_estimate
    FROM 
        customer_demographics
    WHERE 
        cd_purchase_estimate IS NOT NULL
    GROUP BY 
        cd_demo_sk
)
SELECT 
    ca.ca_address_sk,
    ca.ca_city,
    cr.total_web_revenue,
    sr.total_store_revenue,
    sh.total_sales AS store_sales_total,
    md.max_estimate
FROM 
    customer_address ca
LEFT JOIN 
    CustomerRevenue cr ON cr.total_web_revenue > 10000
LEFT JOIN 
    (SELECT 
        ss_store_sk,
        SUM(ss_ext_sales_price) AS total_store_revenue
     FROM 
        store_sales
     GROUP BY 
        ss_store_sk) sr ON sr.ss_store_sk = ca.ca_address_sk
LEFT JOIN 
    SalesHierarchy sh ON sh.ss_store_sk = ca.ca_address_sk
LEFT JOIN 
    MaxDemo md ON md.cd_demo_sk = ca.ca_address_sk
WHERE 
    (ca.ca_state IS NOT NULL OR ca.ca_zip IS NOT NULL)
    AND (cr.total_web_revenue > 5000 OR sr.total_store_revenue < 1000)
ORDER BY 
    ca.ca_city, sh.total_sales DESC
LIMIT 10;
