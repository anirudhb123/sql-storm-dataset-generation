
WITH Recursive CustomerHierarchy AS (
    SELECT 
        c.c_customer_sk, 
        c.c_first_name, 
        c.c_last_name, 
        c.c_current_cdemo_sk, 
        0 AS level
    FROM 
        customer c
    WHERE 
        c.c_current_cdemo_sk IS NOT NULL
    
    UNION ALL
    
    SELECT 
        c.c_customer_sk, 
        c.c_first_name, 
        c.c_last_name, 
        c.c_current_cdemo_sk, 
        ch.level + 1
    FROM 
        customer c
    JOIN 
        CustomerHierarchy ch ON c.c_current_cdemo_sk = ch.c_current_cdemo_sk
)
SELECT 
    ca.ca_city,
    COUNT(DISTINCT c.c_customer_sk) AS unique_customers,
    AVG(CASE WHEN cd.cd_gender = 'M' THEN cd.cd_purchase_estimate END) AS avg_purchase_estimate_males,
    AVG(CASE WHEN cd.cd_gender = 'F' THEN cd.cd_purchase_estimate END) AS avg_purchase_estimate_females,
    SUM(ws.ws_net_profit) AS total_profit,
    MAX(sr_return_amt) AS max_return_amt,
    STRING_AGG(DISTINCT CONCAT(cd.cd_marital_status, ': ', COUNT(DISTINCT c.c_customer_sk)) ORDER BY cd.cd_marital_status) AS marital_status_distribution
FROM 
    customer_address ca
LEFT JOIN 
    customer c ON c.c_current_addr_sk = ca.ca_address_sk
LEFT JOIN 
    customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
LEFT JOIN 
    web_sales ws ON ws.ws_bill_customer_sk = c.c_customer_sk 
LEFT JOIN 
    store_returns sr ON sr.sr_customer_sk = c.c_customer_sk
WHERE 
    ca.ca_state = 'NY'
    AND (cd.cd_purchase_estimate IS NOT NULL OR cd.cd_marital_status IS NOT NULL)
GROUP BY 
    ca.ca_city
HAVING 
    COUNT(DISTINCT c.c_customer_sk) > 10
ORDER BY 
    total_profit DESC
LIMIT 10;
