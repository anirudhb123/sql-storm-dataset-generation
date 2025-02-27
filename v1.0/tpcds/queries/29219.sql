
SELECT 
    ca_city,
    ca_state,
    COUNT(DISTINCT c_first_name || ' ' || c_last_name) AS unique_customers,
    STRING_AGG(DISTINCT c_email_address, ', ') AS all_emails,
    MAX(cd_purchase_estimate) AS highest_purchase_estimate,
    MIN(cd_dep_count) AS lowest_dependents_count,
    AVG(cd_dep_employed_count) AS average_dependent_employed_count,
    SUM(ws_quantity) AS total_quantity_sold,
    SUM(ws_net_paid) AS total_net_paid,
    STRING_AGG(DISTINCT i_product_name, '; ') AS sold_product_names
FROM 
    customer_address
JOIN 
    customer ON ca_address_sk = c_current_addr_sk
JOIN 
    customer_demographics ON c_current_cdemo_sk = cd_demo_sk
JOIN 
    web_sales ON c_customer_sk = ws_bill_customer_sk
JOIN 
    item ON ws_item_sk = i_item_sk
WHERE 
    ca_state IN ('CA', 'TX', 'NY')
    AND cd_gender = 'F'
    AND cd_marital_status = 'M'
GROUP BY 
    ca_city, ca_state
ORDER BY 
    total_net_paid DESC
LIMIT 10;
