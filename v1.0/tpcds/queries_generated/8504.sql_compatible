
WITH ranked_sales AS (
    SELECT 
        ws.bill_customer_sk,
        c.c_gender,
        c.c_birth_year,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        DENSE_RANK() OVER (PARTITION BY c.c_gender, c.c_birth_year ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS sales_rank
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year BETWEEN 2019 AND 2021
    GROUP BY 
        ws.bill_customer_sk, c.c_gender, c.c_birth_year
)

SELECT 
    r.sales_rank,
    r.bill_customer_sk,
    r.total_sales,
    c.c_first_name,
    c.c_last_name,
    c.c_birth_year,
    cd.education_status,
    ib.lower_bound,
    ib.upper_bound
FROM 
    ranked_sales r
JOIN 
    customer c ON r.bill_customer_sk = c.c_customer_sk
JOIN 
    customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
JOIN 
    household_demographics hd ON cd.cd_demo_sk = hd.hd_demo_sk
JOIN 
    income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
WHERE 
    r.sales_rank <= 10
ORDER BY 
    r.total_sales DESC;
