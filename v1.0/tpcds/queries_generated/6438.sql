
WITH sales_summary AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        SUM(ws_net_profit) AS total_profit,
        COUNT(DISTINCT ws_order_number) AS order_count
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023) - 30 
        AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        ws_bill_customer_sk
),
top_customers AS (
    SELECT 
        cs.c_customer_sk,
        cs.c_first_name,
        cs.c_last_name,
        ss.total_sales,
        ss.total_profit,
        ss.order_count,
        RANK() OVER (ORDER BY ss.total_sales DESC) AS sales_rank
    FROM 
        customer cs
    JOIN 
        sales_summary ss ON cs.c_customer_sk = ss.ws_bill_customer_sk
    WHERE 
        cs.c_preferred_cust_flag = 'Y'
)
SELECT 
    tc.c_customer_sk,
    tc.c_first_name,
    tc.c_last_name,
    tc.total_sales,
    tc.total_profit,
    tc.order_count,
    dd.d_year,
    dd.d_month_seq,
    dd.d_day_name
FROM 
    top_customers tc
JOIN 
    date_dim dd ON dd.d_date_sk = (SELECT MAX(ws_sold_date_sk) FROM web_sales WHERE ws_bill_customer_sk = tc.c_customer_sk)
WHERE 
    tc.sales_rank <= 10
ORDER BY 
    tc.total_sales DESC;
