
SELECT 
    c.c_first_name || ' ' || c.c_last_name AS full_name,
    ca.ca_city || ', ' || ca.ca_state || ' ' || ca.ca_zip AS address,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.cd_education_status,
    SUM(ws.ws_sales_price) AS total_sales,
    COUNT(DISTINCT ws.ws_order_number) AS order_count,
    COUNT(DISTINCT ws.ws_web_page_sk) AS unique_web_pages,
    STRING_AGG(DISTINCT wp.wp_url, ', ') AS viewed_web_pages,
    DATE_TRUNC('month', d.d_date) AS sales_month
FROM 
    customer AS c
JOIN 
    customer_address AS ca ON c.c_current_addr_sk = ca.ca_address_sk
JOIN 
    customer_demographics AS cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
JOIN 
    web_sales AS ws ON c.c_customer_sk = ws.ws_bill_customer_sk
JOIN 
    web_page AS wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
JOIN 
    date_dim AS d ON ws.ws_sold_date_sk = d.d_date_sk
WHERE 
    d.d_year = 2023
GROUP BY 
    full_name, address, cd.cd_gender, cd.cd_marital_status, cd.cd_education_status, sales_month
ORDER BY 
    sales_month, total_sales DESC
LIMIT 100;
