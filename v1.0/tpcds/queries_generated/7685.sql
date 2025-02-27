
SELECT 
    d.d_year AS year,
    d.d_month_seq AS month,
    SUM(ws.ws_net_paid_inc_tax) AS total_sales,
    COUNT(DISTINCT c.c_customer_sk) AS unique_customers,
    AVG(i.i_current_price) AS avg_item_price,
    SUM(sr.s_return_amt) AS total_returns,
    COUNT(DISTINCT sr.sr_ticket_number) AS total_returned_items
FROM 
    web_sales ws
JOIN 
    customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
JOIN 
    date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
LEFT JOIN 
    store_returns sr ON ws.ws_item_sk = sr.sr_item_sk AND ws.ws_order_number = sr.sr_ticket_number
JOIN 
    item i ON ws.ws_item_sk = i.i_item_sk
WHERE 
    d.d_year >= 2020 AND d.d_year <= 2023
GROUP BY 
    d.d_year, d.d_month_seq
ORDER BY 
    d.d_year, d.d_month_seq
LIMIT 100;
