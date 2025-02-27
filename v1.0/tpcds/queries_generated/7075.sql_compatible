
WITH customer_sales AS (
    SELECT 
        c.c_customer_sk,
        SUM(ss.ss_sales_price) AS total_store_sales,
        SUM(ws.ws_sales_price) AS total_web_sales,
        SUM(cs.cs_sales_price) AS total_catalog_sales
    FROM 
        customer c
    LEFT JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    LEFT JOIN catalog_sales cs ON c.c_customer_sk = cs.cs_ship_customer_sk
    GROUP BY 
        c.c_customer_sk
),
top_customers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cs.total_store_sales,
        cs.total_web_sales,
        cs.total_catalog_sales,
        (cs.total_store_sales + cs.total_web_sales + cs.total_catalog_sales) AS total_sales
    FROM 
        customer_sales cs
    JOIN customer c ON cs.c_customer_sk = c.c_customer_sk
    ORDER BY total_sales DESC
    LIMIT 10
),
customer_details AS (
    SELECT 
        tc.c_customer_sk,
        tc.c_first_name,
        tc.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        hd.hd_buy_potential,
        hd.hd_income_band_sk
    FROM 
        top_customers tc
    LEFT JOIN customer_demographics cd ON tc.c_customer_sk = cd.cd_demo_sk
    LEFT JOIN household_demographics hd ON cd.cd_demo_sk = hd.hd_demo_sk
)
SELECT 
    cd.c_customer_sk,
    cd.c_first_name,
    cd.c_last_name,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.cd_education_status,
    hd.hd_buy_potential,
    ib.ib_lower_bound,
    ib.ib_upper_bound
FROM 
    customer_details cd
LEFT JOIN income_band ib ON cd.hd_income_band_sk = ib.ib_income_band_sk
ORDER BY cd.c_customer_sk;
