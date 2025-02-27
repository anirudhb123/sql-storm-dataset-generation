
WITH customer_summary AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        SUM(ws.ws_ext_sales_price) AS total_spent,
        COUNT(ws.ws_order_number) AS total_orders,
        COUNT(DISTINCT cs.cs_order_number) AS catalog_orders,
        COUNT(DISTINCT ss.ss_ticket_number) AS store_orders,
        AVG(ws.ws_net_profit) AS avg_profit,
        MAX(ws.ws_net_paid_inc_tax) AS max_spending
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    LEFT JOIN 
        catalog_sales cs ON c.c_customer_sk = cs.cs_ship_customer_sk
    LEFT JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status, cd.cd_education_status
),
date_summary AS (
    SELECT 
        d.d_date_sk,
        d.d_year,
        d.d_month_seq,
        COUNT(DISTINCT ws.ws_order_number) AS web_sales_count,
        SUM(ws.ws_ext_sales_price) AS total_web_sales,
        COUNT(DISTINCT ss.ss_ticket_number) AS store_sales_count,
        SUM(ss.ss_ext_sales_price) AS total_store_sales
    FROM 
        date_dim d
    LEFT JOIN 
        web_sales ws ON d.d_date_sk = ws.ws_sold_date_sk
    LEFT JOIN 
        store_sales ss ON d.d_date_sk = ss.ss_sold_date_sk
    GROUP BY 
        d.d_date_sk, d.d_year, d.d_month_seq
),
final_summary AS (
    SELECT 
        cs.c_customer_sk,
        cs.c_first_name,
        cs.c_last_name,
        cs.total_spent,
        cs.total_orders,
        ds.d_year,
        ds.total_web_sales,
        ds.total_store_sales
    FROM 
        customer_summary cs
    JOIN 
        date_summary ds ON cs.total_orders > 0
)
SELECT 
    f.c_customer_sk,
    f.c_first_name,
    f.c_last_name,
    f.total_spent,
    f.total_orders,
    f.d_year,
    f.total_web_sales,
    f.total_store_sales,
    CASE 
        WHEN f.total_spent > 1000 THEN 'High Value Customer'
        WHEN f.total_spent > 500 THEN 'Medium Value Customer'
        ELSE 'Low Value Customer'
    END AS customer_value_category
FROM 
    final_summary f
ORDER BY 
    f.total_spent DESC;
