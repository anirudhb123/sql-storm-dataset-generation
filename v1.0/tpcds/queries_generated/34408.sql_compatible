
WITH RECURSIVE sales_hierarchy AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        COALESCE(SUM(ws.ws_quantity), 0) AS total_quantity,
        COALESCE(SUM(ws.ws_sales_price), 0) AS total_sales
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
    UNION ALL
    SELECT 
        ch.c_customer_sk,
        ch.c_first_name,
        ch.c_last_name,
        COALESCE(SUM(ws.ws_quantity), 0) + sh.total_quantity AS total_quantity,
        COALESCE(SUM(ws.ws_sales_price), 0) + sh.total_sales AS total_sales
    FROM 
        customer ch
    INNER JOIN 
        sales_hierarchy sh ON ch.c_customer_sk = sh.c_customer_sk
    LEFT JOIN 
        web_sales ws ON ch.c_customer_sk = ws.ws_ship_customer_sk
    GROUP BY 
        ch.c_customer_sk, ch.c_first_name, ch.c_last_name, sh.total_quantity, sh.total_sales
),
date_range AS (
    SELECT 
        MIN(d.d_date) AS start_date,
        MAX(d.d_date) AS end_date
    FROM 
        date_dim d
    WHERE 
        d.d_year = 2023
),
address_info AS (
    SELECT 
        ca.ca_address_sk,
        CONCAT(ca.ca_street_number, ' ', ca.ca_street_name, ' ', ca.ca_city, ', ', ca.ca_state, ' ', ca.ca_zip) AS full_address
    FROM 
        customer_address ca
)

SELECT 
    sh.c_customer_sk,
    sh.c_first_name,
    sh.c_last_name,
    sh.total_quantity,
    sh.total_sales,
    ai.full_address,
    dr.start_date,
    dr.end_date,
    ROW_NUMBER() OVER (PARTITION BY sh.c_customer_sk ORDER BY sh.total_sales DESC) AS sales_rank
FROM 
    sales_hierarchy sh
LEFT JOIN 
    address_info ai ON sh.c_customer_sk = ai.ca_address_sk
CROSS JOIN 
    date_range dr
WHERE 
    sh.total_sales > (SELECT AVG(total_sales) FROM sales_hierarchy)
    AND ai.full_address IS NOT NULL
ORDER BY 
    sh.total_sales DESC;
