
WITH customer_sales AS (
    SELECT 
        c.c_customer_sk,
        SUM(ss.ss_net_paid) AS total_store_sales,
        SUM(ws.ws_net_paid) AS total_web_sales,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        hd.hd_income_band_sk
    FROM 
        customer c
    LEFT JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
    WHERE 
        c.c_birth_year BETWEEN 1980 AND 1995
    GROUP BY 
        c.c_customer_sk, cd.cd_gender, cd.cd_marital_status, cd.cd_education_status, hd.hd_income_band_sk
),
sales_summary AS (
    SELECT 
        gender,
        marital_status,
        education_status,
        income_band_sk,
        COUNT(*) AS customer_count,
        SUM(total_store_sales) AS total_store_sales,
        SUM(total_web_sales) AS total_web_sales,
        AVG(total_store_sales) AS avg_store_sales,
        AVG(total_web_sales) AS avg_web_sales
    FROM (
        SELECT 
            CASE 
                WHEN cd_gender = 'M' THEN 'Male'
                WHEN cd_gender = 'F' THEN 'Female'
                ELSE 'Other'
            END AS gender,
            cd_marital_status AS marital_status,
            cd_education_status AS education_status,
            hd_income_band_sk,
            total_store_sales,
            total_web_sales
        FROM 
            customer_sales
    ) AS sales_data
    GROUP BY 
        gender, marital_status, education_status, income_band_sk
)
SELECT 
    gender,
    marital_status,
    education_status,
    income_band_sk,
    customer_count,
    total_store_sales,
    total_web_sales,
    avg_store_sales,
    avg_web_sales
FROM 
    sales_summary
ORDER BY 
    total_store_sales DESC, total_web_sales DESC;
