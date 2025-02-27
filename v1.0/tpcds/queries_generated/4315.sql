
WITH ranked_sales AS (
    SELECT 
        ws.web_site_id,
        ws_sold_date_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        RANK() OVER (PARTITION BY ws.web_site_id ORDER BY SUM(ws_ext_sales_price) DESC) AS sales_rank
    FROM 
        web_sales ws
    JOIN 
        web_site w ON ws.ws_web_site_sk = w.web_site_sk
    GROUP BY 
        ws.web_site_id, ws_sold_date_sk
),
date_filtered AS (
    SELECT 
        d.d_date AS sales_date,
        d.d_year,
        d.d_month_seq,
        d.d_day_name
    FROM 
        date_dim d
    WHERE 
        d.d_year >= 2020 AND d.d_year <= 2023
),
customer_filter AS (
    SELECT 
        c.c_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_income_band_sk,
        CASE 
            WHEN cd.cd_purchase_estimate > 5000 THEN 'High Value'
            WHEN cd.cd_purchase_estimate BETWEEN 1000 AND 5000 THEN 'Medium Value'
            ELSE 'Low Value'
        END AS customer_value_category
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        cd.cd_gender IS NOT NULL
)
SELECT 
    df.sales_date,
    r.web_site_id,
    r.total_sales,
    cf.customer_value_category,
    COUNT(DISTINCT cf.c_customer_sk) AS unique_customers
FROM 
    ranked_sales r
JOIN 
    date_filtered df ON r.ws_sold_date_sk = df.d_date
JOIN 
    customer_filter cf ON r.web_site_id = cf.c_customer_sk
WHERE 
    r.sales_rank <= 10
GROUP BY 
    df.sales_date, r.web_site_id, cf.customer_value_category
ORDER BY 
    df.sales_date, r.total_sales DESC;
