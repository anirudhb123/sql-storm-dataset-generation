
SELECT 
    c.c_first_name || ' ' || c.c_last_name AS full_name,
    ca.ca_street_number || ' ' || ca.ca_street_name || ' ' || ca.ca_street_type AS address,
    ca.ca_city,
    ca.ca_state,
    ca.ca_zip,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.cd_education_status,
    COUNT(DISTINCT sr.sr_ticket_number) AS total_returns,
    AVG(COALESCE(sr.sr_return_amt, 0)) AS avg_return_amount,
    LISTAGG(DISTINCT r.r_reason_desc, ', ') WITHIN GROUP (ORDER BY r.r_reason_desc) AS return_reasons
FROM customer c
JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
LEFT JOIN store_returns sr ON c.c_customer_sk = sr.sr_customer_sk
LEFT JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
WHERE ca.ca_city IS NOT NULL
GROUP BY 
    c.c_first_name, 
    c.c_last_name, 
    ca.ca_street_number, 
    ca.ca_street_name, 
    ca.ca_street_type, 
    ca.ca_city, 
    ca.ca_state, 
    ca.ca_zip,
    cd.cd_gender, 
    cd.cd_marital_status, 
    cd.cd_education_status
ORDER BY total_returns DESC
LIMIT 100;
