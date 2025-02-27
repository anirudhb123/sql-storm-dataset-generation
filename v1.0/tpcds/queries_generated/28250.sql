
SELECT 
    ca.city AS address_city,
    COUNT(DISTINCT c.c_customer_id) AS total_customers,
    STRING_AGG(DISTINCT CONCAT(c.c_first_name, ' ', c.c_last_name), ', ') AS customer_names,
    SUM(CASE WHEN cd.cd_gender = 'M' THEN 1 ELSE 0 END) AS male_count,
    SUM(CASE WHEN cd.cd_gender = 'F' THEN 1 ELSE 0 END) AS female_count,
    AVG(cd.cd_purchase_estimate) AS average_purchase_estimate,
    STRING_AGG(DISTINCT CONCAT(i.i_item_desc, ' (', i.i_current_price, ')'), '; ') AS popular_items
FROM 
    customer_address ca
JOIN 
    customer c ON ca.ca_address_sk = c.c_current_addr_sk
JOIN 
    customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
LEFT JOIN 
    web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
LEFT JOIN 
    item i ON ws.ws_item_sk = i.i_item_sk
WHERE 
    ca.ca_city IS NOT NULL
GROUP BY 
    ca.city
ORDER BY 
    total_customers DESC
LIMIT 
    10;
