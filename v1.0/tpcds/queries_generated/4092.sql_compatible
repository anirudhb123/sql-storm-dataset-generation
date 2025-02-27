
WITH customer_sales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ss.ss_net_paid) AS total_sales,
        COUNT(ss.ss_ticket_number) AS sale_count
    FROM 
        customer c
    JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    WHERE 
        c.c_birth_year > 1970
        AND c.c_preferred_cust_flag = 'Y'
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
high_value_customers AS (
    SELECT 
        c_customer_sk,
        total_sales,
        RANK() OVER (ORDER BY total_sales DESC) AS sales_rank
    FROM 
        customer_sales
)
SELECT 
    c.c_first_name,
    c.c_last_name,
    c.total_sales,
    d.d_date,
    d.d_day_name,
    (SELECT 
        COUNT(*)
     FROM 
        web_sales ws 
     WHERE 
        ws.ws_bill_customer_sk = c.c_customer_sk) AS online_purchase_count
FROM 
    high_value_customers c
LEFT JOIN 
    date_dim d ON d.d_date_sk = (SELECT MAX(ss.ss_sold_date_sk) FROM store_sales ss WHERE ss.ss_customer_sk = c.c_customer_sk)
WHERE 
    c.sales_rank <= 10
ORDER BY 
    c.total_sales DESC;
