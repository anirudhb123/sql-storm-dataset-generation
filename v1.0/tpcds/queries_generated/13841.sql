
SELECT 
    c.c_customer_id, 
    SUM(ss.ss_sales_price) AS total_sales,
    cd.cd_gender,
    cd.cd_income_band_sk
FROM 
    customer c
JOIN 
    store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
JOIN 
    customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
WHERE 
    cd.cd_marital_status = 'M' 
    AND cd.cd_gender = 'F'
GROUP BY 
    c.c_customer_id, cd.cd_gender, cd.cd_income_band_sk
ORDER BY 
    total_sales DESC
LIMIT 100;
