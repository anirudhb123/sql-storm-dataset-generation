
WITH RECURSIVE customer_sales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        COALESCE(SUM(ws.ws_ext_sales_price), 0) AS total_sales
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
    UNION ALL
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        COALESCE(SUM(cs.cs_ext_sales_price), 0) AS total_sales
    FROM 
        customer c
    JOIN 
        catalog_sales cs ON c.c_customer_sk = cs.cs_ship_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
ranked_sales AS (
    SELECT 
        customer_sales.c_customer_sk,
        customer_sales.c_first_name,
        customer_sales.c_last_name,
        customer_sales.total_sales,
        RANK() OVER (ORDER BY customer_sales.total_sales DESC) AS sales_rank
    FROM 
        customer_sales
),
top_customers AS (
    SELECT 
        rc.c_customer_sk,
        rc.c_first_name,
        rc.c_last_name,
        rc.total_sales
    FROM 
        ranked_sales rc
    WHERE 
        rc.sales_rank <= 10
)
SELECT 
    tc.c_first_name || ' ' || tc.c_last_name AS full_name,
    tc.total_sales,
    CASE 
        WHEN tc.total_sales IS NULL THEN 'No Sales'
        WHEN tc.total_sales < 100 THEN 'Low Sales'
        ELSE 'High Sales'
    END AS sales_category
FROM 
    top_customers tc
LEFT JOIN 
    customer_address ca ON ca.ca_address_sk = (
        SELECT c_current_addr_sk 
        FROM customer 
        WHERE c_customer_sk = tc.c_customer_sk
    )
WHERE 
    ca.ca_city IS NOT NULL
ORDER BY 
    tc.total_sales DESC;
