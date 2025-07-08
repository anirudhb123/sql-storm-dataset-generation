
SELECT 
    ca_state,
    COUNT(DISTINCT c_customer_sk) AS unique_customers,
    AVG(cd_purchase_estimate) AS average_purchase_estimate,
    LISTAGG(DISTINCT ca_city, ', ') WITHIN GROUP (ORDER BY ca_city) AS cities,
    SUM(ss_net_profit) AS total_net_profit
FROM 
    customer_address AS ca
JOIN 
    customer AS c ON ca.ca_address_sk = c.c_current_addr_sk
JOIN 
    customer_demographics AS cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
LEFT JOIN 
    store_sales AS ss ON c.c_customer_sk = ss.ss_customer_sk
GROUP BY 
    ca_state
HAVING 
    COUNT(DISTINCT c_customer_sk) > 50
ORDER BY 
    total_net_profit DESC;
