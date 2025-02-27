
SELECT 
    ca.ca_city AS city,
    COUNT(DISTINCT c.c_customer_id) AS customer_count,
    AVG(cd_purchase_estimate) AS avg_purchase_estimate,
    SUM(CASE WHEN cd_gender = 'M' THEN 1 ELSE 0 END) AS male_count,
    SUM(CASE WHEN cd_gender = 'F' THEN 1 ELSE 0 END) AS female_count,
    LISTAGG(DISTINCT CONCAT(c.c_first_name, ' ', c.c_last_name), ', ') WITHIN GROUP (ORDER BY c.c_last_name) AS customer_names,
    SUBSTRING(ca.ca_street_name FROM 1 FOR 10) AS street_name_prefix,
    COUNT(DISTINCT s.s_store_id) AS store_count,
    SUM((ws_ext_sales_price - ws_ext_discount_amt) / NULLIF(ws_ext_sales_price, 0)) AS avg_discount_percentage
FROM 
    customer_address ca
JOIN 
    customer c ON ca.ca_address_sk = c.c_current_addr_sk
JOIN 
    customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
LEFT JOIN 
    web_sales w ON c.c_customer_sk = w.ws_bill_customer_sk
LEFT JOIN 
    store s ON c.c_current_hdemo_sk = s.s_hdemo_sk
WHERE 
    ca.ca_state = 'CA'
GROUP BY 
    ca.ca_city
ORDER BY 
    customer_count DESC
LIMIT 10;
