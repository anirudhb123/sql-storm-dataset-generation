
WITH RECURSIVE monthly_sales AS (
    SELECT 
        d_year,
        d_month_seq,
        SUM(ws_net_paid) AS total_sales
    FROM 
        web_sales
    JOIN 
        date_dim ON ws_sold_date_sk = d_date_sk
    GROUP BY 
        d_year, d_month_seq
    
    UNION ALL
    
    SELECT 
        d_year,
        d_month_seq,
        SUM(cs_net_paid) AS total_sales
    FROM 
        catalog_sales
    JOIN 
        date_dim ON cs_sold_date_sk = d_date_sk
    GROUP BY 
        d_year, d_month_seq
),
ranked_sales AS (
    SELECT 
        d_year,
        d_month_seq,
        SUM(total_sales) AS total_monthly_sales,
        RANK() OVER (PARTITION BY d_year ORDER BY SUM(total_sales) DESC) AS sales_rank
    FROM 
        monthly_sales
    GROUP BY 
        d_year, d_month_seq
),
customer_summary AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        SUM(ws.net_profit) AS total_spent,
        COUNT(ws.ws_order_number) AS total_orders
    FROM 
        customer c
    LEFT OUTER JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT OUTER JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        cd.cd_marital_status = 'M' AND
        (cd.cd_gender = 'F' OR cd.cd_gender IS NULL)
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status
),
top_customers AS (
    SELECT 
        cas.c_customer_sk,
        cas.c_first_name,
        cas.c_last_name,
        cas.total_spent,
        RANK() OVER (ORDER BY cas.total_spent DESC) AS customer_rank
    FROM 
        customer_summary cas
)

SELECT 
    r.d_year,
    r.d_month_seq,
    tc.c_customer_sk,
    tc.c_first_name,
    tc.c_last_name,
    tc.total_spent,
    r.sales_rank
FROM 
    ranked_sales r
JOIN 
    top_customers tc ON r.sales_rank <= 10
ORDER BY 
    r.d_year, r.d_month_seq, tc.total_spent DESC;
