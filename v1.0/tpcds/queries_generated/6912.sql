
SELECT 
    ca_state, 
    SUM(ws_net_profit) AS total_net_profit, 
    COUNT(DISTINCT ws_bill_customer_sk) AS unique_customers, 
    AVG(ws_net_paid_inc_tax) AS avg_net_paid,
    COUNT(ws_order_number) AS total_orders,
    COUNT(DISTINCT ws_web_page_sk) AS unique_web_pages,
    DATE_FORMAT(STR_TO_DATE(CONCAT(d_year, '-', d_month_seq, '-', d_dom), '%Y-%m-%u-%u'), '%Y-%m') AS month_year
FROM 
    web_sales ws
JOIN 
    customer_address ca ON ws_bill_addr_sk = ca.ca_address_sk
JOIN 
    date_dim dd ON ws_sold_date_sk = d_date_sk
WHERE 
    d_year = 2023 
    AND ca_state IN ('TX', 'CA', 'NY')
GROUP BY 
    ca_state, month_year
ORDER BY 
    ca_state, month_year;
