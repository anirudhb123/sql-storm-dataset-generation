
SELECT 
    ca.ca_city,
    COUNT(DISTINCT c.c_customer_id) AS customer_count,
    STRING_AGG(DISTINCT CONCAT(c.c_first_name, ' ', c.c_last_name), ', ') AS customer_names,
    SUM(CASE WHEN cd_gender = 'M' THEN 1 ELSE 0 END) AS male_count,
    SUM(CASE WHEN cd_gender = 'F' THEN 1 ELSE 0 END) AS female_count,
    AVG(cd_purchase_estimate) AS avg_purchase_estimate,
    MAX(cd_credit_rating) AS highest_credit_rating,
    STRING_AGG(DISTINCT cd_marital_status) AS marital_statuses,
    (SELECT 
        COUNT(*) 
     FROM 
        web_returns wr 
     JOIN 
        web_sales ws ON wr.wr_item_sk = ws.ws_item_sk 
     WHERE 
        ws.ws_ship_addr_sk = ca.ca_address_sk) AS return_count
FROM 
    customer_address ca
JOIN 
    customer c ON ca.ca_address_sk = c.c_current_addr_sk
JOIN 
    customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
WHERE 
    ca.ca_state = 'CA'
GROUP BY 
    ca.ca_city
ORDER BY 
    customer_count DESC;
