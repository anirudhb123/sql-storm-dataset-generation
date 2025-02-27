
WITH RECURSIVE sales_data AS (
    SELECT 
        ss.sold_date_sk,
        ss.ss_item_sk,
        SUM(ss.ss_quantity) AS total_sales_quantity,
        SUM(ss.ss_net_paid) AS total_sales_amount,
        ROW_NUMBER() OVER (PARTITION BY ss.ss_item_sk ORDER BY SUM(ss.ss_net_paid) DESC) AS sales_rank
    FROM 
        store_sales ss
    WHERE 
        ss.ss_sold_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023) 
        AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        ss.sold_date_sk, ss.ss_item_sk
    HAVING 
        SUM(ss.ss_quantity) > 0
),
customer_revenue AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_net_paid) AS total_revenue
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
top_customers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cr.total_revenue,
        DENSE_RANK() OVER (ORDER BY cr.total_revenue DESC) AS revenue_rank
    FROM 
        customer_revenue cr
    JOIN 
        customer c ON cr.c_customer_sk = c.c_customer_sk
)
SELECT 
    a.cd_gender,
    ca.ca_city,
    SUM(sd.total_sales_quantity) AS total_quantity_sold,
    COUNT(DISTINCT tc.c_customer_sk) AS unique_buyers,
    AVG(tc.total_revenue) AS avg_revenue_per_customer
FROM 
    sales_data sd
JOIN 
    item i ON sd.ss_item_sk = i.i_item_sk
JOIN 
    store s ON s.s_store_sk = sd.ss_item_sk
JOIN 
    customer c ON c.c_customer_sk = sd.ss_item_sk
LEFT JOIN 
    customer_demographics a ON c.c_current_cdemo_sk = a.cd_demo_sk
LEFT JOIN 
    top_customers tc ON c.c_customer_sk = tc.c_customer_sk
LEFT JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
WHERE 
    a.cd_gender IS NOT NULL
    AND tc.revenue_rank <= 10
GROUP BY 
    a.cd_gender, ca.ca_city;
