
SELECT 
    ca_state,
    COUNT(DISTINCT c_customer_id) AS unique_customers,
    SUM(ss_net_profit) AS total_net_profit,
    AVG(i_current_price) AS avg_item_price,
    STRING_AGG(DISTINCT cd_marital_status, ', ') AS marital_statuses,
    GROUP_CONCAT(DISTINCT CONCAT(c_first_name, ' ', c_last_name) ORDER BY c_last_name) AS customer_names
FROM 
    customer_address AS ca
JOIN 
    customer AS c ON ca.ca_address_sk = c.c_current_addr_sk
JOIN 
    store_sales AS ss ON c.c_customer_sk = ss.ss_customer_sk
JOIN 
    item AS i ON ss.ss_item_sk = i.i_item_sk
JOIN 
    customer_demographics AS cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
WHERE 
    ca_state IS NOT NULL
    AND ss_sold_date_sk IN (
        SELECT d_date_sk FROM date_dim WHERE d_year = 2023
    )
GROUP BY 
    ca_state
ORDER BY 
    total_net_profit DESC
LIMIT 10;
