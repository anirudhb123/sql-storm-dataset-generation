
SELECT 
    ca_state,
    COUNT(DISTINCT c_customer_id) AS unique_customers,
    AVG(cd_purchase_estimate) AS avg_purchase_estimate,
    SUM(ws_quantity) AS total_quantity_sold,
    STRING_AGG(DISTINCT CONCAT(c_first_name, ' ', c_last_name), ', ') AS top_customers,
    SUBSTRING(w.warehouse_name FROM 1 FOR 20) AS warehouse_name_excerpt
FROM 
    customer_address ca
JOIN 
    customer c ON ca.ca_address_sk = c.c_current_addr_sk
JOIN 
    customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
JOIN 
    web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
JOIN 
    warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
WHERE 
    ca_state IN ('CA', 'NY', 'TX') 
    AND cd_credit_rating IN ('Silver', 'Gold')
GROUP BY 
    ca_state
HAVING 
    COUNT(DISTINCT c_customer_id) > 100
ORDER BY 
    avg_purchase_estimate DESC;
