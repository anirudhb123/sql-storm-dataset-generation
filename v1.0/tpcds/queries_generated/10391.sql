
SELECT 
    SUM(ws_ext_sales_price) AS total_sales,
    d_year,
    d_month_seq,
    c_gender,
    c_marital_status
FROM 
    web_sales
JOIN 
    date_dim ON ws_sold_date_sk = d_date_sk
JOIN 
    customer AS c ON ws_bill_customer_sk = c.c_customer_sk
JOIN 
    customer_demographics AS cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
GROUP BY 
    d_year, d_month_seq, c_gender, c_marital_status
ORDER BY 
    d_year, d_month_seq;
