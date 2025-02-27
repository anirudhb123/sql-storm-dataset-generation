
WITH ranked_sales AS (
    SELECT 
        ws.bill_customer_sk,
        SUM(ws.ext_sales_price) AS total_sales,
        RANK() OVER (PARTITION BY ws.bill_customer_sk ORDER BY SUM(ws.ext_sales_price) DESC) AS sales_rank
    FROM 
        web_sales ws
    WHERE 
        ws.sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        ws.bill_customer_sk
),
customer_info AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_income_band_sk,
        cd.cd_marital_status
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.current_cdemo_sk = cd.cd_demo_sk
),
customer_sales AS (
    SELECT 
        ci.full_name,
        ci.cd_gender,
        ci.cd_income_band_sk,
        ci.cd_marital_status,
        rs.total_sales
    FROM 
        ranked_sales rs
    JOIN 
        customer_info ci ON rs.bill_customer_sk = ci.c_customer_sk
    WHERE 
        rs.sales_rank = 1
)
SELECT 
    ci.full_name,
    ci.cd_gender,
    COALESCE(ib.ib_lower_bound, 0) AS income_lower_bound,
    COALESCE(ib.ib_upper_bound, 0) AS income_upper_bound,
    cs.total_sales
FROM 
    customer_sales cs
LEFT JOIN 
    household_demographics hd ON cs.cd_income_band_sk = hd.hd_income_band_sk
LEFT JOIN 
    income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
WHERE 
    cs.total_sales > (SELECT AVG(total_sales) FROM customer_sales)
ORDER BY 
    cs.total_sales DESC;
