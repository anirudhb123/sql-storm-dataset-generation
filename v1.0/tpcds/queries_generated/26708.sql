
SELECT 
    c.c_first_name || ' ' || c.c_last_name AS full_name,
    count(DISTINCT ws.ws_order_number) AS total_web_orders,
    sum(ws.ws_ext_sales_price) AS total_web_sales,
    sum(ws.ws_ext_discount_amt) AS total_discounts,
    (SELECT COUNT(*) 
     FROM customer_address ca 
     WHERE ca.ca_city ILIKE '%' || c.c_city || '%') AS similar_addresses_count,
    d.d_year AS order_year,
    EXTRACT(MONTH FROM d.d_date) AS order_month
FROM 
    customer c
JOIN 
    web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
JOIN 
    date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
WHERE 
    c.c_birth_year BETWEEN 1980 AND 1990
    AND d.d_date BETWEEN '2022-01-01' AND '2022-12-31'
GROUP BY 
    full_name, order_year, order_month
ORDER BY 
    total_web_sales DESC
LIMIT 10;
