
SELECT 
    c.c_customer_id,
    count(sr.ticket_number) AS return_count,
    sum(sr.return_amt_inc_tax) AS total_return_amount,
    avg(sr.return_quantity) AS avg_quantity_returned,
    d.d_date AS return_date
FROM 
    store_returns sr
JOIN 
    customer c ON sr.s_customer_sk = c.c_customer_sk
JOIN 
    date_dim d ON sr.returned_date_sk = d.d_date_sk
WHERE 
    d.d_year = 2023
GROUP BY 
    c.c_customer_id, d.d_date
ORDER BY 
    return_date DESC, return_count DESC
LIMIT 100;
