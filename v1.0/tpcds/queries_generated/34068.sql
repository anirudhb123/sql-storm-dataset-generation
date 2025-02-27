
WITH RECURSIVE CustomerHierarchy AS (
    SELECT c_customer_sk, c_first_name, c_last_name, c_current_addr_sk, 1 AS hierarchy_level
    FROM customer
    WHERE c_customer_sk IS NOT NULL

    UNION ALL

    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, c.c_current_addr_sk, ch.hierarchy_level + 1
    FROM customer c
    JOIN CustomerHierarchy ch ON c.c_current_addr_sk = ch.c_current_addr_sk
)
SELECT 
    ca.ca_city, 
    ca.ca_state,
    cd.cd_gender,
    COUNT(DISTINCT c.c_customer_sk) AS total_customers,
    SUM(COALESCE(ws.ws_sales_price, 0)) AS total_sales
FROM 
    customer_address ca
JOIN 
    customer c ON ca.ca_address_sk = c.c_current_addr_sk
LEFT JOIN 
    customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
LEFT JOIN 
    web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
JOIN 
    CustomerHierarchy ch ON c.c_customer_sk = ch.c_customer_sk
WHERE 
    ca.ca_state = 'CA'
AND 
    cd.cd_marital_status = 'M'
AND 
    (
        (SELECT COUNT(*) FROM store_sales ss WHERE ss.ss_customer_sk = c.c_customer_sk) > 0
        OR ws.ws_net_paid > 100
    )
GROUP BY 
    ca.ca_city, 
    ca.ca_state, 
    cd.cd_gender
HAVING 
    total_sales > 5000
ORDER BY 
    total_sales DESC;
