
SELECT 
    CA.ca_city,
    CA.ca_state,
    COUNT(DISTINCT C.c_customer_id) AS customer_count,
    SUM(CASE WHEN CD.cd_gender = 'M' THEN 1 ELSE 0 END) AS male_count,
    SUM(CASE WHEN CD.cd_gender = 'F' THEN 1 ELSE 0 END) AS female_count,
    AVG(DATE_PART('year', AGE(CAST(CONCAT(C.c_birth_year, '-', C.c_birth_month, '-', C.c_birth_day) AS DATE)))) AS average_age,
    STRING_AGG(DISTINCT I.i_product_name, ', ') AS popular_products,
    SUM(W.ws_sales_price) AS total_sales,
    COUNT(DISTINCT W.ws_order_number) AS order_count
FROM 
    customer C
JOIN 
    customer_address CA ON C.c_current_addr_sk = CA.ca_address_sk
JOIN 
    customer_demographics CD ON C.c_current_cdemo_sk = CD.cd_demo_sk
JOIN 
    web_sales W ON C.c_customer_sk = W.ws_bill_customer_sk
JOIN 
    item I ON W.ws_item_sk = I.i_item_sk
WHERE 
    CA.ca_state IN ('CA', 'NY')
    AND CD.cd_marital_status = 'M'
GROUP BY 
    CA.ca_city, CA.ca_state
ORDER BY 
    total_sales DESC
LIMIT 10;
