
SELECT 
    c.c_customer_id, 
    c.c_first_name, 
    c.c_last_name, 
    SUM(ss.ss_quantity) AS total_quantity_sold, 
    SUM(ss.ss_net_paid_inc_tax) AS total_sales_amount, 
    COUNT(DISTINCT ss.ss_ticket_number) AS total_transactions, 
    dd.d_year AS sales_year, 
    dd.d_month_seq AS sales_month,
    sm.sm_type AS shipping_type,
    COUNT(DISTINCT ws.ws_web_page_sk) AS unique_web_pages_viewed,
    AVG(ss.ss_sales_price) AS avg_sales_price,
    MAX(ss.ss_sales_price) AS max_sales_price,
    MIN(ss.ss_sales_price) AS min_sales_price
FROM 
    customer c
JOIN 
    store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
JOIN 
    date_dim dd ON ss.ss_sold_date_sk = dd.d_date_sk
JOIN 
    ship_mode sm ON ss.ss_ship_mode_sk = sm.sm_ship_mode_sk
LEFT JOIN 
    web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
WHERE 
    dd.d_year BETWEEN 2020 AND 2023
    AND sm.sm_type IN ('STANDARD CLASS', 'SECOND DAY AIR')
GROUP BY 
    c.c_customer_id, 
    c.c_first_name, 
    c.c_last_name, 
    dd.d_year, 
    dd.d_month_seq,
    sm.sm_type
ORDER BY 
    total_sales_amount DESC
LIMIT 100;
