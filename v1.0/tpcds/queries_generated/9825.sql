
SELECT 
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    SUM(ss.ss_quantity) AS total_quantity,
    SUM(ss.ss_net_paid) AS total_net_paid,
    COUNT(DISTINCT ws.ws_order_number) AS sales_order_count,
    d.d_year,
    d.d_month_seq,
    ca.ca_city,
    ca.ca_state
FROM 
    customer AS c
JOIN 
    store_sales AS ss ON c.c_customer_sk = ss.ss_customer_sk
JOIN 
    date_dim AS d ON ss.ss_sold_date_sk = d.d_date_sk
JOIN 
    customer_address AS ca ON c.c_current_addr_sk = ca.ca_address_sk
WHERE 
    d.d_year BETWEEN 2021 AND 2023
    AND ss.ss_sold_date_sk IN (
        SELECT DISTINCT 
            ws_sold_date_sk 
        FROM 
            web_sales 
        WHERE 
            ws_net_profit > 100
    )
GROUP BY 
    c.c_customer_id, c.c_first_name, c.c_last_name, d.d_year, d.d_month_seq, ca.ca_city, ca.ca_state
ORDER BY 
    total_net_paid DESC, total_quantity DESC
LIMIT 10;
