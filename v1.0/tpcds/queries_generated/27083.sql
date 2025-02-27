
WITH CustomerSales AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_ext_sales_price) AS total_spent,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_id, c.c_first_name, c.c_last_name
),
DemographicsData AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cs.total_spent,
        cs.order_count
    FROM 
        customer_demographics cd
    JOIN 
        CustomerSales cs ON cs.c_customer_id = (SELECT c_customer_id FROM customer WHERE c_current_cdemo_sk = cd.cd_demo_sk)
)
SELECT 
    dd.d_year,
    dd.d_month_seq,
    dd.d_quarter_seq,
    SUM(CASE WHEN dd.d_month_seq BETWEEN 1 AND 3 THEN dd.total_spent ELSE 0 END) AS Q1_spending,
    SUM(CASE WHEN dd.d_month_seq BETWEEN 4 AND 6 THEN dd.total_spent ELSE 0 END) AS Q2_spending,
    SUM(CASE WHEN dd.d_month_seq BETWEEN 7 AND 9 THEN dd.total_spent ELSE 0 END) AS Q3_spending,
    SUM(CASE WHEN dd.d_month_seq BETWEEN 10 AND 12 THEN dd.total_spent ELSE 0 END) AS Q4_spending,
    COUNT(DISTINCT cs.c_customer_id) AS unique_customers
FROM 
    DemographicsData dd
JOIN 
    date_dim dd ON dd.d_date_sk = (SELECT ws.ws_sold_date_sk FROM web_sales ws WHERE ws.ws_bill_customer_sk = dd.c_customer_id LIMIT 1)
GROUP BY 
    dd.d_year, dd.d_month_seq, dd.d_quarter_seq
ORDER BY 
    dd.d_year, dd.d_month_seq;
