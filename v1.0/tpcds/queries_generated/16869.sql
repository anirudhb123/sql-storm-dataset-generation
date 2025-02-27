
SELECT 
    c_first_name, 
    c_last_name, 
    ca_city, 
    cs_sales_price 
FROM 
    customer 
JOIN 
    customer_address ON customer.c_current_addr_sk = customer_address.ca_address_sk 
JOIN 
    store_sales ON customer.c_customer_sk = store_sales.ss_customer_sk 
JOIN 
    item ON store_sales.ss_item_sk = item.i_item_sk 
WHERE 
    ca_city = 'San Francisco' 
ORDER BY 
    cs_sales_price DESC 
LIMIT 10;
