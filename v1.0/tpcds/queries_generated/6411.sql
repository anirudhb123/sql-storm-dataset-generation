
WITH ranked_sales AS (
    SELECT 
        ws.bill_customer_sk,
        SUM(ws.ext_sales_price) AS total_sales,
        COUNT(ws.order_number) AS order_count,
        ROW_NUMBER() OVER (PARTITION BY ws.bill_customer_sk ORDER BY SUM(ws.ext_sales_price) DESC) AS sales_rank
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.bill_customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        date_dim dd ON ws.sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2023 AND 
        (cd.cd_gender = 'F' AND cd.cd_marital_status = 'M' OR cd.cd_education_status IN ('Bachelor', 'Master'))
    GROUP BY 
        ws.bill_customer_sk
),
top_customers AS (
    SELECT 
        bill_customer_sk, 
        total_sales, 
        order_count
    FROM 
        ranked_sales
    WHERE 
        sales_rank <= 10
)
SELECT 
    tc.bill_customer_sk, 
    tc.total_sales, 
    tc.order_count, 
    c.c_first_name, 
    c.c_last_name, 
    ca.ca_city, 
    ca.ca_state
FROM 
    top_customers tc
JOIN 
    customer c ON tc.bill_customer_sk = c.c_customer_sk
JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
ORDER BY 
    tc.total_sales DESC;
