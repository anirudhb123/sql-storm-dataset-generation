
SELECT 
    ca.city AS address_city,
    COUNT(DISTINCT c.c_customer_sk) AS unique_customers,
    SUM(CASE WHEN cd.gender = 'F' THEN 1 ELSE 0 END) AS female_customers,
    SUM(CASE WHEN cd.marital_status = 'M' THEN 1 ELSE 0 END) AS married_customers,
    AVG(CASE WHEN cd.education_status LIKE '%Bachelor%' THEN cd.purchase_estimate ELSE NULL END) AS average_bachelor_purchase_estimate,
    STRING_AGG(DISTINCT CONCAT(i.brand, ' - ', i.product_name), '; ') AS product_brands,
    COUNT(DISTINCT CASE WHEN ws.net_profit > 0 THEN ws.ws_order_number END) AS profitable_orders
FROM 
    customer_address ca
JOIN 
    customer c ON ca.ca_address_sk = c.c_current_addr_sk
JOIN 
    customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
JOIN 
    web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
JOIN 
    item i ON ws.ws_item_sk = i.i_item_sk
WHERE 
    ca.city IS NOT NULL 
    AND cd.education_status IS NOT NULL 
    AND ws.ws_sold_date_sk BETWEEN (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023) - 30 AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
GROUP BY 
    ca.city
ORDER BY 
    unique_customers DESC
LIMIT 10;
