
WITH RECURSIVE sales_hierarchy AS (
    SELECT 
        s.s_store_sk,
        s.s_store_name,
        s.s_country,
        1 AS level,
        SUM(ws.ws_net_paid) AS total_sales
    FROM 
        store s
    JOIN 
        web_sales ws ON s.s_store_sk = ws.ws_warehouse_sk
    GROUP BY 
        s.s_store_sk, s.s_store_name, s.s_country
    
    UNION ALL
    
    SELECT 
        sh.s_store_sk,
        sh.s_store_name,
        sh.s_country,
        sh.level + 1,
        SUM(ws.ws_net_paid) AS total_sales
    FROM 
        sales_hierarchy sh
    JOIN 
        store s ON s.s_store_sk = sh.s_store_sk
    JOIN 
        web_sales ws ON s.s_store_sk = ws.ws_warehouse_sk
    GROUP BY 
        sh.s_store_sk, sh.s_store_name, sh.s_country, sh.level
)
SELECT 
    ca.ca_city,
    ca.ca_state,
    SUM(ss.ss_net_paid) AS total_store_sales,
    COUNT(DISTINCT c.c_customer_id) AS unique_customers,
    AVG(cd.cd_purchase_estimate) AS avg_purchase_estimate,
    COUNT(ws.ws_order_number) AS total_transactions,
    MAX(ss.ss_sales_price) AS max_sale_price,
    STRING_AGG(DISTINCT CONCAT(cd.cd_gender, ': ', cd.cd_marital_status) ORDER BY cd.cd_gender) AS demographic_snapshot,
    CASE 
        WHEN AVG(ss.ss_net_paid) IS NULL THEN 'No Sales'
        WHEN AVG(ss.ss_net_paid) > 100 THEN 'High Sales'
        ELSE 'Normal Sales' 
    END AS sales_category
FROM 
    store_sales ss
LEFT JOIN 
    customer c ON ss.ss_customer_sk = c.c_customer_sk
LEFT JOIN 
    customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
INNER JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
LEFT JOIN 
    sales_hierarchy sh ON sh.s_store_sk = ss.ss_store_sk
WHERE 
    sh.level < 3 AND 
    ca.ca_state IS NOT NULL
GROUP BY 
    ca.ca_city, ca.ca_state
HAVING 
    SUM(ss.ss_net_paid) > 5000
ORDER BY 
    total_store_sales DESC;
