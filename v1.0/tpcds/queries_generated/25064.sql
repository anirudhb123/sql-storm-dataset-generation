
SELECT 
    ca.ca_city,
    COUNT(DISTINCT c.c_customer_id) AS customer_count,
    COUNT(DISTINCT ws.ws_order_number) AS web_sales_count,
    SUM(ws.ws_net_paid_inc_tax) AS total_web_sales,
    SUBSTRING_INDEX(SUBSTRING_INDEX(c.c_email_address, '@', -1), '.', 1) AS email_domain,
    GROUP_CONCAT(DISTINCT i.i_item_desc ORDER BY i.i_item_desc) AS popular_items
FROM 
    customer_address ca
JOIN 
    customer c ON ca.ca_address_sk = c.c_current_addr_sk
LEFT JOIN 
    web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
LEFT JOIN 
    item i ON ws.ws_item_sk = i.i_item_sk
WHERE 
    ca.ca_city IS NOT NULL
GROUP BY 
    ca.ca_city, email_domain
HAVING 
    customer_count > 5
ORDER BY 
    total_web_sales DESC
LIMIT 10;
