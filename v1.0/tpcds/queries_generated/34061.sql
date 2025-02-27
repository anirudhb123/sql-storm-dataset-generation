
WITH RECURSIVE sales_hierarchy AS (
    SELECT 
        cs.customer_sk,
        cs.order_number,
        cs.item_sk,
        cs.sales_price,
        1 AS level
    FROM 
        catalog_sales cs
    WHERE 
        cs_sold_date_sk = (SELECT MAX(cs_sold_date_sk) FROM catalog_sales)
    
    UNION ALL
    
    SELECT 
        sr.returning_customer_sk,
        sr.order_number,
        sr.item_sk,
        sr.return_amt * -1 AS sales_price,
        sh.level + 1
    FROM 
        store_returns sr
    JOIN 
        sales_hierarchy sh ON sr.item_sk = sh.item_sk AND sr.order_number = sh.order_number
)
SELECT 
    ca.city,
    SUM(DISTINCT sh.sales_price) AS total_sales,
    AVG(cd_purchase_estimate) AS avg_purchase_estimate,
    MAX(CASE WHEN cd_gender = 'M' THEN cd_purchase_estimate END) AS max_male_purchase_estimate,
    MIN(CASE WHEN cd_gender = 'F' THEN cd_purchase_estimate END) AS min_female_purchase_estimate,
    ROW_NUMBER() OVER (PARTITION BY ca.state ORDER BY SUM(sh.sales_price) DESC) AS rank_within_state,
    COUNT(DISTINCT c.c_customer_id) as unique_customers
FROM 
    customer_address ca
JOIN 
    customer c ON ca.ca_address_sk = c.c_current_addr_sk
JOIN 
    customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
JOIN 
    sales_hierarchy sh ON c.c_customer_sk = sh.customer_sk 
GROUP BY 
    ca.city, ca.state
HAVING 
    SUM(sh.sales_price) IS NOT NULL 
    AND COUNT(DISTINCT c.c_customer_id) > 0
ORDER BY 
    total_sales DESC;
