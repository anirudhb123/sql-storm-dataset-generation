
WITH sales_summary AS (
    SELECT 
        ws.web_site_sk,
        SUM(ws.ws_quantity) AS total_quantity_sold,
        SUM(ws.ws_sales_price) AS total_sales_amount,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM 
        web_sales ws
    JOIN 
        web_site w ON ws.ws_web_site_sk = w.web_site_sk
    WHERE 
        w.web_state = 'CA'
    GROUP BY 
        ws.web_site_sk
),
customer_info AS (
    SELECT 
        c.c_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        SUM(ws.ws_sales_price) AS total_spent
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    WHERE 
        c.c_birth_year BETWEEN 1980 AND 1990
    GROUP BY 
        c.c_customer_sk, cd.cd_gender, cd.cd_marital_status, cd.cd_education_status
),
date_info AS (
    SELECT 
        d.d_year,
        d.d_month_seq,
        SUM(ws.ws_ext_sales_price) AS month_sales
    FROM 
        date_dim d
    JOIN 
        web_sales ws ON d.d_date_sk = ws.ws_sold_date_sk
    WHERE 
        d.d_year = 2023
    GROUP BY 
        d.d_year, d.d_month_seq
)
SELECT 
    ss.web_site_sk,
    ss.total_quantity_sold,
    ss.total_sales_amount,
    ss.total_orders,
    ci.cd_gender,
    ci.cd_marital_status,
    ci.cd_education_status,
    ci.total_spent,
    di.d_month_seq,
    di.month_sales
FROM 
    sales_summary ss
JOIN 
    customer_info ci ON ss.web_site_sk IN (
        SELECT DISTINCT 
            ws.ws_web_site_sk
        FROM 
            web_sales ws
        WHERE 
            ws.ws_sales_price > 100
    )
JOIN 
    date_info di ON di.month_sales > 5000
ORDER BY 
    ss.total_sales_amount DESC, ci.total_spent DESC;
