
WITH demographics AS (
    SELECT 
        cd_gender, 
        cd_education_status, 
        COUNT(DISTINCT c.c_customer_id) AS customer_count,
        SUM(CASE WHEN cd_marital_status = 'M' THEN 1 ELSE 0 END) AS married_count,
        SUM(CASE WHEN cd_marital_status = 'S' THEN 1 ELSE 0 END) AS single_count,
        SUM(cd_purchase_estimate) AS total_purchase_estimation,
        AVG(cd_dep_count) AS average_dependencies
    FROM 
        customer_demographics cd 
    JOIN 
        customer c ON cd.cd_demo_sk = c.c_current_cdemo_sk 
    GROUP BY 
        cd_gender, cd_education_status
), 
address_summary AS (
    SELECT 
        ca_state, 
        COUNT(DISTINCT c.c_customer_id) AS associated_customers,
        LISTAGG(DISTINCT ca_city, ', ') AS cities_list
    FROM 
        customer_address ca 
    JOIN 
        customer c ON ca.ca_address_sk = c.c_current_addr_sk 
    GROUP BY 
        ca_state
) 
SELECT 
    d.cd_gender, 
    d.cd_education_status, 
    d.customer_count, 
    d.married_count, 
    d.single_count, 
    d.total_purchase_estimation, 
    d.average_dependencies,
    a.associated_customers,
    a.cities_list
FROM 
    demographics d 
LEFT JOIN 
    address_summary a ON a.associated_customers > 0
ORDER BY 
    d.customer_count DESC;
