
SELECT 
    c.c_first_name,
    c.c_last_name,
    d.d_date,
    ws.ws_web_page_id,
    SUM(ws.ws_quantity) AS total_quantity,
    SUM(ws.ws_net_paid) AS total_net_paid
FROM 
    web_sales ws
JOIN 
    customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
JOIN 
    date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
GROUP BY 
    c.c_first_name,
    c.c_last_name,
    d.d_date,
    ws.ws_web_page_id
ORDER BY 
    total_net_paid DESC
LIMIT 10;
