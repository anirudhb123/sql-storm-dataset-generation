
SELECT 
    ca.ca_city,
    COUNT(DISTINCT c.c_customer_id) AS num_customers,
    SUM(cs.ss_ext_sales_price) AS total_sales,
    MIN(cs.ss_sales_price) AS min_item_price,
    MAX(cs.ss_sales_price) AS max_item_price,
    AVG(cs.ss_sales_price) AS avg_item_price,
    STRING_AGG(DISTINCT i.i_product_name, ', ') AS popular_items
FROM 
    customer_address ca
JOIN customer c ON ca.ca_address_sk = c.c_current_addr_sk
JOIN store_sales cs ON c.c_customer_sk = cs.ss_customer_sk
JOIN item i ON cs.ss_item_sk = i.i_item_sk
WHERE 
    ca.ca_state = 'CA'
    AND cs.ss_sold_date_sk BETWEEN 2459497 AND 2459500
GROUP BY 
    ca.ca_city
ORDER BY 
    total_sales DESC
LIMIT 10;
