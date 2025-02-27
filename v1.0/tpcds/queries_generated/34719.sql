
WITH RECURSIVE customer_hierarchy AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        c.c_current_cdemo_sk,
        NULL AS parent_cdemo_sk
    FROM 
        customer c
    WHERE 
        c.c_current_cdemo_sk IS NOT NULL

    UNION ALL

    SELECT 
        ch.c_customer_sk,
        ch.c_first_name,
        ch.c_last_name,
        ch.c_current_cdemo_sk,
        ch.c_current_cdemo_sk AS parent_cdemo_sk
    FROM 
        customer_hierarchy ch
    JOIN 
        customer c ON ch.c_current_cdemo_sk = c.c_current_cdemo_sk
)
SELECT 
    ca.ca_city,
    ca.ca_state,
    COUNT(DISTINCT c.c_customer_sk) AS customer_count,
    AVG(cd.cd_purchase_estimate) AS average_purchase_estimate,
    SUM(ws.ws_net_profit) AS total_net_profit,
    STRING_AGG(DISTINCT CONCAT(c.c_first_name, ' ', c.c_last_name), ', ') AS customer_names
FROM 
    customer_address ca
LEFT JOIN 
    customer c ON c.c_current_addr_sk = ca.ca_address_sk
LEFT JOIN 
    customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
LEFT JOIN 
    web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
WHERE 
    (cd.cd_marital_status = 'M' OR cd.cd_marital_status IS NULL)
    AND (cd.cd_gender = 'F' OR cd.cd_gender IS NULL)
    AND EXISTS (
        SELECT 1
        FROM customer_hierarchy ch
        WHERE ch.c_customer_sk = c.c_customer_sk
    )
GROUP BY 
    ca.ca_city, ca.ca_state
HAVING 
    COUNT(DISTINCT c.c_customer_sk) > 10
ORDER BY 
    total_net_profit DESC
LIMIT 50;
