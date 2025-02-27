
WITH sales_summary AS (
    SELECT 
        ws.web_site_sk,
        SUM(ws.ws_sales_price * ws.ws_quantity) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        AVG(ws.ws_net_paid) AS average_order_value,
        COUNT(DISTINCT ws.ws_bill_customer_sk) AS unique_customers
    FROM 
        web_sales ws
    JOIN 
        web_site w ON ws.ws_web_site_sk = w.web_site_sk
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year BETWEEN 2021 AND 2023
    GROUP BY 
        ws.web_site_sk
),
customer_info AS (
    SELECT 
        c.c_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cs.total_sales,
        cs.total_orders,
        cs.average_order_value,
        cs.unique_customers
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        sales_summary cs ON cs.web_site_sk = (
            SELECT web_site_sk 
            FROM web_sales 
            WHERE ws_bill_customer_sk = c.c_customer_sk 
            LIMIT 1
        )
),
gender_distributions AS (
    SELECT 
        cd_gender,
        COUNT(c_customer_sk) AS num_customers,
        SUM(total_sales) AS gender_sales,
        AVG(average_order_value) AS avg_order_value,
        SUM(total_orders) AS total_orders
    FROM 
        customer_info
    GROUP BY 
        cd_gender
)
SELECT 
    gd.cd_gender,
    gd.num_customers,
    gd.gender_sales,
    gd.avg_order_value,
    gd.total_orders,
    (1.0 * gd.gender_sales / NULLIF(SUM(gender_sales) OVER(), 0)) * 100 AS percentage_of_sales
FROM 
    gender_distributions gd
ORDER BY 
    gd.gender_sales DESC;
