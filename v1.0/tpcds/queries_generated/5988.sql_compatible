
WITH customer_sales AS (
    SELECT 
        c.c_customer_sk,
        SUM(ws.ws_quantity) AS total_web_sales,
        SUM(cs.cs_quantity) AS total_cat_sales,
        SUM(ss.ss_quantity) AS total_store_sales
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN 
        catalog_sales cs ON c.c_customer_sk = cs.cs_bill_customer_sk
    LEFT JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY 
        c.c_customer_sk
),
customer_info AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_income_band_sk,
        cd.cd_credit_rating,
        ca.ca_city,
        ca.ca_state,
        cs.total_web_sales,
        cs.total_cat_sales,
        cs.total_store_sales
    FROM 
        customer_demographics cd
    JOIN 
        customer_address ca ON cd.cd_demo_sk = ca.ca_address_sk
    JOIN 
        customer_sales cs ON cd.cd_demo_sk = cs.c_customer_sk
),
sales_analysis AS (
    SELECT 
        ci.cd_gender,
        ci.cd_marital_status,
        ci.cd_income_band_sk,
        SUM(ci.total_web_sales) AS total_web_sales,
        SUM(ci.total_cat_sales) AS total_cat_sales,
        SUM(ci.total_store_sales) AS total_store_sales,
        COUNT(DISTINCT ci.cd_demo_sk) AS customer_count
    FROM 
        customer_info ci
    GROUP BY 
        ci.cd_gender, ci.cd_marital_status, ci.cd_income_band_sk
)
SELECT 
    sa.cd_gender,
    sa.cd_marital_status,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    sa.total_web_sales,
    sa.total_cat_sales,
    sa.total_store_sales,
    sa.customer_count
FROM 
    sales_analysis sa
JOIN 
    income_band ib ON sa.cd_income_band_sk = ib.ib_income_band_sk
ORDER BY 
    sa.cd_gender, sa.cd_marital_status, ib.ib_lower_bound;
