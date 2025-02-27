
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        SUM(ss.ss_net_paid) AS total_sales,
        cd.cd_gender,
        cd.cd_marital_status,
        hd.hd_income_band_sk
    FROM 
        customer c
    JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        household_demographics hd ON cd.cd_demo_sk = hd.hd_demo_sk
    WHERE 
        ss.ss_sold_date_sk >= (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023)
        AND ss.ss_sold_date_sk <= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        c.c_customer_sk, cd.cd_gender, cd.cd_marital_status, hd.hd_income_band_sk
),
RankedSales AS (
    SELECT
        cs.c_customer_sk,
        cs.total_sales,
        RANK() OVER (PARTITION BY cs.hd_income_band_sk ORDER BY cs.total_sales DESC) AS sales_rank
    FROM 
        CustomerSales cs
)
SELECT 
    r.hd_income_band_sk,
    COUNT(*) AS num_customers,
    SUM(r.total_sales) AS total_income,
    AVG(r.total_sales) AS average_income
FROM 
    RankedSales r
WHERE 
    r.sales_rank <= 10
GROUP BY 
    r.hd_income_band_sk
ORDER BY 
    total_income DESC;
