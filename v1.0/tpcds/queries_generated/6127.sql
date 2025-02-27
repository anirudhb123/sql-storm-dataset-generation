
SELECT 
    c.c_customer_id, 
    c.c_first_name, 
    c.c_last_name, 
    SUM(s.ws_ext_sales_price) AS total_sales, 
    COUNT(DISTINCT w.ws_order_number) AS order_count, 
    AVG(i.i_current_price) AS average_item_price, 
    d.d_year, 
    d.d_month_seq 
FROM 
    customer c 
JOIN 
    web_sales s ON c.c_customer_sk = s.ws_bill_customer_sk 
JOIN 
    item i ON s.ws_item_sk = i.i_item_sk 
JOIN 
    date_dim d ON s.ws_sold_date_sk = d.d_date_sk 
JOIN 
    web_site w ON s.ws_web_site_sk = w.web_site_sk 
WHERE 
    d.d_year = 2023 
    AND w.web_class = 'Retail' 
GROUP BY 
    c.c_customer_id, c.c_first_name, c.c_last_name, d.d_year, d.d_month_seq 
HAVING 
    SUM(s.ws_ext_sales_price) > 1000 
ORDER BY 
    total_sales DESC 
LIMIT 100;
