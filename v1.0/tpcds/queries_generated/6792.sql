
WITH customer_data AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating,
        hd.hd_income_band_sk,
        SUM(ss.ss_sales_price) AS total_sales,
        COUNT(DISTINCT ss.ss_ticket_number) AS purchase_count,
        DENSE_RANK() OVER (ORDER BY SUM(ss.ss_sales_price) DESC) AS sales_rank
    FROM 
        customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
    LEFT JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    WHERE 
        c.c_birth_year >= 1980
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, 
        cd.cd_marital_status, cd.cd_education_status, cd.cd_purchase_estimate, 
        cd.cd_credit_rating, hd.hd_income_band_sk
),
top_customers AS (
    SELECT * FROM customer_data WHERE sales_rank <= 100
)
SELECT 
    tc.c_customer_sk,
    tc.c_first_name,
    tc.c_last_name,
    tc.cd_gender,
    tc.cd_marital_status,
    tc.cd_education_status,
    tc.cd_purchase_estimate,
    tc.cd_credit_rating,
    ib.ib_income_band_sk,
    SUM(ws.ws_ext_sales_price) AS web_sales_total,
    SUM(cs.cs_ext_sales_price) AS catalog_sales_total,
    SUM(ss.ss_ext_sales_price) AS store_sales_total
FROM 
    top_customers tc
LEFT JOIN web_sales ws ON tc.c_customer_sk = ws.ws_bill_customer_sk
LEFT JOIN catalog_sales cs ON tc.c_customer_sk = cs.cs_bill_customer_sk
LEFT JOIN income_band ib ON tc.hd_income_band_sk = ib.ib_income_band_sk
GROUP BY 
    tc.c_customer_sk, tc.c_first_name, tc.c_last_name, tc.cd_gender, 
    tc.cd_marital_status, tc.cd_education_status, tc.cd_purchase_estimate, 
    tc.cd_credit_rating, ib.ib_income_band_sk
ORDER BY 
    web_sales_total DESC, catalog_sales_total DESC, store_sales_total DESC;
