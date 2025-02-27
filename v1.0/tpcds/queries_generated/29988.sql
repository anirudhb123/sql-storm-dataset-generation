
SELECT 
    CONCAT(c.c_first_name, ' ', c.c_last_name) AS customer_name,
    ca.ca_city AS city,
    ca.ca_state AS state,
    d.d_date AS transaction_date,
    SUM(ws.ws_sales_price) AS total_sales
FROM 
    customer AS c
JOIN 
    customer_address AS ca ON c.c_current_addr_sk = ca.ca_address_sk
JOIN 
    web_sales AS ws ON c.c_customer_sk = ws.ws_bill_customer_sk
JOIN 
    date_dim AS d ON ws.ws_sold_date_sk = d.d_date_sk
WHERE 
    c.c_birth_year BETWEEN 1980 AND 1995
    AND (ca.ca_city LIKE '%New%' OR ca.ca_state = 'CA')
GROUP BY 
    customer_name, city, state, transaction_date
HAVING 
    total_sales > 500
ORDER BY 
    transaction_date DESC, total_sales DESC;
