
SELECT 
    SUM(ws_ext_sales_price) AS total_sales,
    d_year,
    c_gender,
    COUNT(DISTINCT c_customer_sk) AS num_customers
FROM 
    web_sales 
JOIN 
    date_dim ON ws_sold_date_sk = d_date_sk
JOIN 
    customer ON ws_bill_customer_sk = c_customer_sk
JOIN 
    customer_demographics ON c_current_cdemo_sk = cd_demo_sk
GROUP BY 
    d_year, c_gender
ORDER BY 
    d_year, c_gender;
