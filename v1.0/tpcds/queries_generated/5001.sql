
WITH sales_data AS (
    SELECT 
        ws.web_site_id,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        EXTRACT(YEAR FROM d.d_date) AS sales_year,
        EXTRACT(MONTH FROM d.d_date) AS sales_month
    FROM 
        web_sales ws
        JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
        JOIN web_site w ON ws.ws_web_site_sk = w.web_site_sk
    WHERE 
        d.d_date BETWEEN '2022-01-01' AND '2022-12-31'
    GROUP BY 
        ws.web_site_id, sales_year, sales_month
),
customer_info AS (
    SELECT 
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_credit_rating,
        cd.cd_dep_count
    FROM 
        customer c
        JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
sales_per_customer AS (
    SELECT 
        ci.c_customer_id,
        SUM(sd.total_sales) AS customer_total_sales,
        SUM(sd.total_quantity) AS customer_total_quantity
    FROM 
        customer_info ci
        JOIN sales_data sd ON ci.c_customer_id = sd.web_site_id
    GROUP BY 
        ci.c_customer_id
)
SELECT 
    ci.cd_gender,
    ci.cd_marital_status,
    AVG(spc.customer_total_sales) AS avg_sales,
    AVG(spc.customer_total_quantity) AS avg_quantity
FROM 
    customer_info ci
    JOIN sales_per_customer spc ON ci.c_customer_id = spc.c_customer_id
GROUP BY 
    ci.cd_gender,
    ci.cd_marital_status
ORDER BY 
    avg_sales DESC, 
    avg_quantity DESC;
