
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_sales_price) AS total_sales
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN 
        date_dim dd ON dd.d_date_sk = ws.ws_sold_date_sk
    WHERE 
        dd.d_year BETWEEN 2020 AND 2023
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
DemographicAnalysis AS (
    SELECT 
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        AVG(cs.total_sales) AS avg_sales_per_customer
    FROM 
        CustomerSales cs
    JOIN 
        customer_demographics cd ON cs.c_customer_sk = cd.cd_demo_sk
    GROUP BY 
        cd.cd_gender, cd.cd_marital_status, cd.cd_education_status
)
SELECT 
    da.cd_gender,
    da.cd_marital_status,
    da.cd_education_status,
    da.avg_sales_per_customer,
    COUNT(cs.c_customer_sk) AS customer_count
FROM 
    DemographicAnalysis da
JOIN 
    CustomerSales cs ON da.cd_gender = (SELECT cd_gender FROM customer_demographics WHERE cd_demo_sk = cs.c_customer_sk)
GROUP BY 
    da.cd_gender, da.cd_marital_status, da.cd_education_status, da.avg_sales_per_customer
ORDER BY 
    da.avg_sales_per_customer DESC;
