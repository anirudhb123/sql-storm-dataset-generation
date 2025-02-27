
SELECT 
    c.c_customer_id,
    CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
    ca.ca_city,
    ca.ca_state,
    COUNT(DISTINCT wr.wr_order_number) AS total_web_returns,
    SUM(wr.wr_return_amt) AS total_return_amount,
    STRING_AGG(DISTINCT r.r_reason_desc, ', ') AS return_reasons,
    AVG(LENGTH(wp.wp_url)) AS avg_url_length,
    MAX(CASE 
        WHEN c.c_birth_month = 12 THEN 'Birthday in December'
        WHEN c.c_birth_month BETWEEN 6 AND 8 THEN 'Summer Birthdays'
        ELSE 'Other Birth Months' 
    END) AS birthday_category
FROM 
    customer c
JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
LEFT JOIN 
    web_returns wr ON c.c_customer_sk = wr.wr_returning_customer_sk
LEFT JOIN 
    web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
LEFT JOIN 
    reason r ON wr.wr_reason_sk = r.r_reason_sk
WHERE 
    c.c_first_name IS NOT NULL 
    AND c.c_last_name IS NOT NULL
GROUP BY 
    c.c_customer_id, c.c_first_name, c.c_last_name, ca.ca_city, ca.ca_state
ORDER BY 
    total_return_amount DESC
LIMIT 100;
