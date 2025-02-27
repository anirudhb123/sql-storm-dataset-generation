
WITH sales_data AS (
    SELECT 
        ws.web_site_id,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        AVG(ws.ws_sales_price) AS avg_sales_price,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2023
    GROUP BY ws.web_site_id
),
top_sales AS (
    SELECT 
        web_site_id, 
        total_sales,
        ROW_NUMBER() OVER (ORDER BY total_sales DESC) AS sales_rank
    FROM sales_data
),
customer_data AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_income_band_sk,
        CASE 
            WHEN cd.cd_dep_count > 2 THEN 'High Dependency'
            ELSE 'Low Dependency'
        END AS dependency_label
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
active_customers AS (
    SELECT DISTINCT 
        c.c_customer_sk, 
        c.c_first_name, 
        c.c_last_name
    FROM customer c
    JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE ws.ws_sold_date_sk IN (
        SELECT d.d_date_sk 
        FROM date_dim d 
        WHERE d.d_year = 2023
    )
)
SELECT 
    cs.c_first_name,
    cs.c_last_name,
    cs.cd_gender,
    csa.dependency_label,
    ts.web_site_id,
    ts.total_sales,
    ts.order_count
FROM active_customers cs
JOIN customer_data csa ON cs.c_customer_sk = csa.c_customer_sk
JOIN top_sales ts ON ts.sales_rank <= 10
LEFT JOIN web_site w ON w.web_site_id = ts.web_site_id
WHERE 
    (w.web_country = 'USA' OR w.web_country IS NULL)
    AND csa.cd_income_band_sk IS NOT NULL
ORDER BY ts.total_sales DESC, cs.c_last_name, cs.c_first_name;
