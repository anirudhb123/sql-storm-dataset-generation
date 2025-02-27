
WITH RECURSIVE sales_hierarchy AS (
    SELECT 
        cs_bill_customer_sk AS customer_sk,
        SUM(cs_ext_sales_price) AS total_sales,
        1 AS level
    FROM 
        catalog_sales
    GROUP BY 
        cs_bill_customer_sk
    UNION ALL
    SELECT 
        s.ss_customer_sk,
        sh.total_sales * 1.1 AS total_sales,
        sh.level + 1
    FROM 
        store_sales s
    JOIN 
        sales_hierarchy sh ON s.ss_customer_sk = sh.customer_sk
    WHERE 
        sh.total_sales > 1000
)
SELECT 
    ca.city,
    ca.state,
    SUM(COALESCE(sh.total_sales, 0)) AS total_sales,
    COUNT(DISTINCT c.c_customer_id) AS customer_count,
    AVG(cd.cd_purchase_estimate) AS avg_purchase_estimate,
    COUNT(DISTINCT CASE WHEN cd.cd_credit_rating IS NULL THEN c.c_customer_id END) AS null_credit_count
FROM 
    customer_address ca
LEFT JOIN 
    customer c ON ca.ca_address_sk = c.c_current_addr_sk
LEFT JOIN 
    customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
LEFT JOIN 
    sales_hierarchy sh ON c.c_customer_sk = sh.customer_sk
WHERE 
    ca.ca_state IN ('CA', 'NY')
GROUP BY 
    ca.city, ca.state
HAVING 
    SUM(sh.total_sales) >= 10000
ORDER BY 
    total_sales DESC
LIMIT 10
OFFSET 5;
