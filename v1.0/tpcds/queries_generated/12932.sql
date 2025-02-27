
SELECT 
    c.c_customer_id, 
    SUM(cs.cs_sales_price) AS total_sales, 
    cd.cd_gender, 
    d.d_year, 
    s.s_store_name 
FROM 
    customer c 
JOIN 
    catalog_sales cs ON c.c_customer_sk = cs.cs_bill_customer_sk 
JOIN 
    customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk 
JOIN 
    date_dim d ON cs.cs_sold_date_sk = d.d_date_sk 
JOIN 
    store s ON cs.cs_store_sk = s.s_store_sk 
WHERE 
    d.d_year = 2023 
GROUP BY 
    c.c_customer_id, cd.cd_gender, d.d_year, s.s_store_name 
ORDER BY 
    total_sales DESC 
LIMIT 100;
