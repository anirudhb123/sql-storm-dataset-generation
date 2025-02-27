
SELECT 
    c.c_first_name || ' ' || c.c_last_name AS full_name,
    ca.ca_street_number || ' ' || ca.ca_street_name || ' ' || ca.ca_street_type AS full_address,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.cd_education_status,
    COUNT(rr.cr_order_number) AS total_returns,
    SUM(rr.cr_return_amount) AS total_returned_amount,
    SUM(rr.cr_return_tax) AS total_returned_tax,
    MAX(rr.cr_return_ship_cost) AS max_return_ship_cost,
    MIN(rr.cr_return_ship_cost) AS min_return_ship_cost
FROM 
    customer c
JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
JOIN 
    customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
LEFT JOIN 
    catalog_returns rr ON c.c_customer_sk = rr.cr_returning_customer_sk 
WHERE 
    cd.cd_gender = 'F' 
    AND ca.ca_city = 'San Francisco' 
    AND rr.cr_return_date_sk > 10000 
GROUP BY 
    c.c_first_name, 
    c.c_last_name, 
    ca.ca_street_number, 
    ca.ca_street_name, 
    ca.ca_street_type, 
    cd.cd_gender, 
    cd.cd_marital_status, 
    cd.cd_education_status
ORDER BY 
    total_returned_amount DESC;
