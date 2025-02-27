
WITH RECURSIVE sales_hierarchy AS (
    SELECT 
        s_store_sk,
        s_store_name,
        SUM(ss_net_profit) AS total_profit,
        1 AS level
    FROM
        store s
    JOIN 
        store_sales ss ON s.s_store_sk = ss.ss_store_sk
    GROUP BY 
        s_store_sk, s_store_name
    
    UNION ALL
    
    SELECT 
        sh.s_store_sk,
        sh.s_store_name,
        sh.total_profit * 1.1 AS total_profit,
        level + 1
    FROM 
        sales_hierarchy sh
    JOIN 
        store s ON sh.s_store_sk = s.s_store_sk
    WHERE 
        level < 5
)
SELECT 
    ca_state,
    COUNT(DISTINCT c_customer_sk) AS unique_customers,
    AVG(cd_purchase_estimate) AS avg_purchase_estimate,
    MAX(total_profit) AS max_store_profit,
    MIN(total_profit) AS min_store_profit,
    STRING_AGG(DISTINCT c_first_name || ' ' || c_last_name, ', ') AS customer_names
FROM 
    customer_address ca
JOIN 
    customer c ON ca.ca_address_sk = c.c_current_addr_sk
JOIN 
    customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
JOIN 
    sales_hierarchy sh ON sh.s_store_sk = c.c_current_addr_sk
WHERE 
    cd_gender = 'F' 
    AND cd_marital_status = 'M' 
    AND cd_purchase_estimate > (SELECT AVG(cd_purchase_estimate) FROM customer_demographics WHERE cd_gender = 'F')
GROUP BY 
    ca_state
ORDER BY 
    unique_customers DESC
LIMIT 10;
