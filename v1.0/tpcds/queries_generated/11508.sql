
SELECT 
    ca_state,
    COUNT(DISTINCT c_customer_sk) AS unique_customers,
    SUM(ss_sales_price) AS total_sales,
    AVG(p_discount_active) AS avg_discount_active
FROM 
    customer_address CA
JOIN 
    customer C ON CA.ca_address_sk = C.c_current_addr_sk
JOIN 
    store_sales SS ON C.c_customer_sk = SS.ss_customer_sk
LEFT JOIN 
    promotion P ON SS.ss_promo_sk = P.p_promo_sk
GROUP BY 
    ca_state
ORDER BY 
    total_sales DESC
LIMIT 10;
