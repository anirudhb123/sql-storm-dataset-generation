
SELECT 
    ca.city AS address_city,
    ca.state AS address_state,
    COUNT(DISTINCT c.customer_id) AS total_customers,
    STRING_AGG(DISTINCT CONCAT(c.first_name, ' ', c.last_name), ', ') AS customer_names,
    SUM(CASE 
        WHEN cd.marital_status = 'M' THEN 1 
        ELSE 0 
    END) AS married_customers,
    AVG(cd.purchase_estimate) AS avg_purchase_estimate,
    MAX(cd.credit_rating) AS highest_credit_rating,
    MIN(cd.dep_count) AS min_dependents,
    STRING_AGG(DISTINCT p.promo_name, '; ') AS promotions_used
FROM 
    customer_address ca
JOIN 
    customer c ON c.current_addr_sk = ca.ca_address_sk
JOIN 
    customer_demographics cd ON cd.cd_demo_sk = c.current_cdemo_sk
LEFT JOIN 
    web_sales ws ON ws.bill_customer_sk = c.c_customer_sk
LEFT JOIN 
    promotion p ON p.promo_sk = ws.promo_sk
WHERE 
    ca.city IS NOT NULL 
AND 
    ca.state IN ('CA', 'NY')
GROUP BY 
    ca.city, ca.state
ORDER BY 
    total_customers DESC;
