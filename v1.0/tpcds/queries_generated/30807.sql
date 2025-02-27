
WITH RECURSIVE AddressHierarchy AS (
    SELECT ca_address_sk, ca_city, ca_state, ca_country
    FROM customer_address
    WHERE ca_country IS NOT NULL
    UNION ALL
    SELECT ca.ca_address_sk, ca.ca_city, ca.ca_state, ca.ca_country
    FROM customer_address ca
    JOIN AddressHierarchy ah ON ah.ca_country = ca.ca_country
)
SELECT 
    c.c_customer_id,
    CONCAT(c.c_first_name, ' ', c.c_last_name) AS customer_name,
    cd.cd_gender,
    cd.cd_marital_status,
    SUM(ws.ws_net_profit) AS total_profit,
    COUNT(DISTINCT ws.ws_order_number) AS order_count,
    MAX(ws.ws_sold_date_sk) AS last_order_date,
    ax.ca_city,
    ax.ca_state
FROM 
    customer c
JOIN 
    customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
LEFT JOIN 
    web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
JOIN 
    AddressHierarchy ax ON c.c_current_addr_sk = ax.ca_address_sk
WHERE 
    cd.cd_purchase_estimate > 1000 
    AND cd.cd_gender = 'F' 
    AND (ws.ws_net_paid_inc_tax - ws.ws_ext_discount_amt) > 50
GROUP BY 
    c.c_customer_id, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status, ax.ca_city, ax.ca_state
HAVING 
    total_profit > 5000
ORDER BY 
    total_profit DESC
LIMIT 10;

