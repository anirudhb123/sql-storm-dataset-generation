
SELECT 
    ca.ca_city,
    COUNT(DISTINCT c.c_customer_id) AS num_customers,
    SUM(CASE WHEN cd_gender = 'F' THEN 1 ELSE 0 END) AS female_count,
    SUM(CASE WHEN cd_gender = 'M' THEN 1 ELSE 0 END) AS male_count,
    AVG(cd_purchase_estimate) AS avg_purchase_estimate,
    MIN(d.d_date) AS first_purchase_date,
    MAX(d.d_date) AS last_purchase_date,
    STRING_AGG(DISTINCT item.i_category, ', ') AS categories_purchased
FROM 
    customer_address ca
JOIN 
    customer c ON ca.ca_address_sk = c.c_current_addr_sk
JOIN 
    customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
JOIN 
    web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
JOIN 
    date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
JOIN 
    item ON ws.ws_item_sk = item.i_item_sk
WHERE 
    ca.ca_city IS NOT NULL
    AND d.d_year >= 2020
GROUP BY 
    ca.ca_city
ORDER BY 
    num_customers DESC
LIMIT 10;
