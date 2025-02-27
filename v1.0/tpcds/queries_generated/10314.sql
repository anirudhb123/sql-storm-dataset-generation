
SELECT 
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    COUNT(sr.ticket_number) AS return_count
FROM 
    customer c
LEFT JOIN 
    store_returns sr ON c.c_customer_sk = sr.sr_customer_sk
WHERE 
    c.c_birth_year < 1980
GROUP BY 
    c.c_customer_id, c.c_first_name, c.c_last_name
ORDER BY 
    return_count DESC
LIMIT 100;
