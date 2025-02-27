
WITH RECURSIVE sales_hierarchy AS (
    SELECT 
        s.s_store_sk, 
        s.s_store_name, 
        SUM(cs.cs_sales_price) AS total_revenue
    FROM 
        store AS s
    JOIN 
        store_sales AS cs ON s.s_store_sk = cs.ss_store_sk
    GROUP BY 
        s.s_store_sk, s.s_store_name
    UNION ALL 
    SELECT 
        sh.s_store_sk, 
        sh.s_store_name, 
        sh.total_revenue + COALESCE(SUM(cs.cs_sales_price), 0)
    FROM 
        sales_hierarchy AS sh
    LEFT JOIN 
        store_sales AS cs ON sh.s_store_sk = cs.ss_store_sk
    GROUP BY 
        sh.s_store_sk, sh.s_store_name, sh.total_revenue
)
SELECT 
    ca.ca_city, 
    COUNT(DISTINCT c.c_customer_sk) AS customer_count,
    AVG(COALESCE(cd.cd_purchase_estimate, 0)) AS avg_purchase_estimate,
    SUM(CASE WHEN cd.cd_gender = 'F' THEN 1 ELSE 0 END) AS female_count,
    SUM(CASE WHEN cd.cd_marital_status = 'M' AND cd.cd_gender = 'M' THEN 1 ELSE 0 END) AS married_male_count,
    SUM(cs.net_profit) AS total_sales_profit,
    row_number() OVER (PARTITION BY ca.ca_city ORDER BY total_sales_profit DESC) AS rank_city
FROM 
    customer AS c
JOIN 
    customer_demographics AS cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
JOIN 
    customer_address AS ca ON c.c_current_addr_sk = ca.ca_address_sk
LEFT JOIN 
    store_sales AS cs ON c.c_customer_sk = cs.ss_customer_sk
WHERE 
    ca.ca_country = 'USA' 
    AND (cd.cd_purchase_estimate IS NOT NULL OR cd.cd_gender IS NOT NULL)
GROUP BY 
    ca.ca_city
HAVING 
    COUNT(DISTINCT c.c_customer_sk) > 0
ORDER BY 
    ranking_city ASC
LIMIT 10;
