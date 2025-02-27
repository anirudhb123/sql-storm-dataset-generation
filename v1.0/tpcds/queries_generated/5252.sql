
WITH customer_sales AS (
    SELECT 
        c.c_customer_id,
        SUM(COALESCE(ws.ws_ext_sales_price, 0) + COALESCE(cs.cs_ext_sales_price, 0) + COALESCE(ss.ss_ext_sales_price, 0)) AS total_sales
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN 
        catalog_sales cs ON c.c_customer_sk = cs.cs_bill_customer_sk
    LEFT JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY 
        c.c_customer_id
),
top_customers AS (
    SELECT 
        c.customer_id,
        cs.total_sales,
        ROW_NUMBER() OVER (ORDER BY cs.total_sales DESC) AS sales_rank
    FROM 
        customer_sales cs
    JOIN 
        customer c ON cs.c_customer_id = c.c_customer_id
),
customer_addresses AS (
    SELECT 
        ca.ca_address_id, 
        ca.ca_city, 
        ca.ca_state,
        tc.sales_rank
    FROM 
        customer_address ca
    JOIN 
        top_customers tc ON tc.customer_id = ca.ca_address_sk
    WHERE 
        tc.sales_rank <= 10
)
SELECT 
    ca.ca_address_id,
    ca.ca_city, 
    ca.ca_state,
    tc.total_sales
FROM 
    customer_addresses ca
JOIN 
    top_customers tc ON ca.sales_rank = tc.sales_rank
ORDER BY 
    tc.total_sales DESC;
