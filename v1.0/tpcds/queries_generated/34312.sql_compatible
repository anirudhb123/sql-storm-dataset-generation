
WITH RECURSIVE CustomerHierarchy AS (
    SELECT 
        c_customer_sk,
        c_first_name,
        c_last_name,
        c_current_addr_sk,
        0 AS level
    FROM 
        customer
    WHERE 
        c_customer_sk IS NOT NULL
    UNION ALL
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        c.c_current_addr_sk,
        ch.level + 1
    FROM 
        customer c
    JOIN 
        CustomerHierarchy ch ON c.c_current_addr_sk = ch.c_current_addr_sk
    WHERE 
        ch.level < 3
)
SELECT 
    ca.ca_city,
    ca.ca_state,
    COUNT(DISTINCT ch.c_customer_sk) AS customer_count,
    AVG(cd.cd_purchase_estimate) AS avg_purchase_estimate,
    SUM(COALESCE(ws.ws_net_profit, 0)) AS total_net_profit,
    STRING_AGG(DISTINCT i.i_product_name) AS product_names,
    RANK() OVER (PARTITION BY ca.ca_state ORDER BY COUNT(DISTINCT ch.c_customer_sk) DESC) AS state_rank
FROM 
    customer_address ca
LEFT JOIN 
    customer c ON c.c_current_addr_sk = ca.ca_address_sk
LEFT JOIN 
    customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
LEFT JOIN 
    web_sales ws ON ws.ws_bill_customer_sk = c.c_customer_sk
JOIN 
    CustomerHierarchy ch ON c.c_customer_sk = ch.c_customer_sk
JOIN 
    item i ON ws.ws_item_sk = i.i_item_sk
WHERE 
    (cd.cd_gender = 'F' OR cd.cd_marital_status = 'S')
    AND (i.i_current_price > 20.00 OR (ws.ws_net_profit IS NULL AND cd.cd_credit_rating IS NOT NULL))
GROUP BY 
    ca.ca_city,
    ca.ca_state,
    cd.cd_purchase_estimate,
    i.i_product_name
HAVING 
    COUNT(DISTINCT ch.c_customer_sk) > 5
ORDER BY 
    total_net_profit DESC
LIMIT 100;
