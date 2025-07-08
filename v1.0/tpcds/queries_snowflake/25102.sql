
SELECT 
    ca_city, 
    ca_state, 
    COUNT(DISTINCT c_customer_sk) AS unique_customers, 
    SUM(ws_ext_sales_price) AS total_sales, 
    AVG(CASE 
            WHEN cd_gender = 'M' THEN ws_ext_sales_price 
            ELSE NULL 
        END) AS avg_male_sales,
    LISTAGG(DISTINCT cd_education_status, ', ') AS education_statuses,
    MAX(ws_sales_price) AS max_sales_price,
    MIN(ws_sales_price) AS min_sales_price
FROM 
    customer_address ca
JOIN 
    customer c ON ca.ca_address_sk = c.c_current_addr_sk
JOIN 
    web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
JOIN 
    customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
WHERE 
    ca_state IN ('CA', 'NY') 
    AND c.c_birth_year BETWEEN 1970 AND 1990 
GROUP BY 
    ca_city, 
    ca_state
ORDER BY 
    total_sales DESC;
