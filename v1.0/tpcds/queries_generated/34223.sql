
WITH RECURSIVE sales_hierarchy AS (
    SELECT 
        cs.cs_order_number,
        cs.cs_sales_price,
        cs.cs_quantity,
        cs.cs_ext_sales_price,
        cs.cs_ship_mode_sk,
        cs.cs_sold_date_sk,
        1 AS level
    FROM
        catalog_sales cs
    WHERE
        cs.cs_sold_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2022) 
        AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2022)

    UNION ALL

    SELECT 
        cs.cs_order_number,
        cs.cs_sales_price * 0.9 AS cs_sales_price,  -- Hypothetical discount for next level
        cs.cs_quantity + 1 AS cs_quantity,
        cs.cs_ext_sales_price * 0.9 AS cs_ext_sales_price,
        cs.cs_ship_mode_sk,
        cs.cs_sold_date_sk,
        sh.level + 1
    FROM
        catalog_sales cs
    JOIN
        sales_hierarchy sh ON cs.cs_order_number = sh.cs_order_number
    WHERE
        sh.level < 3  -- Limit recursion to levels
),

customer_orders AS (
    SELECT 
        c.c_customer_id,
        SUM(sh.cs_ext_sales_price) AS total_sales,
        COUNT(DISTINCT sh.cs_order_number) AS order_count
    FROM 
        customer c
    JOIN 
        sales_hierarchy sh ON c.c_customer_sk = sh.cs_ship_customer_sk
    GROUP BY 
        c.c_customer_id
),

top_customers AS (
    SELECT 
        co.c_customer_id,
        co.total_sales,
        DENSE_RANK() OVER (ORDER BY co.total_sales DESC) AS sales_rank
    FROM 
        customer_orders co
)

SELECT 
    tc.c_customer_id,
    tc.total_sales,
    CASE 
        WHEN tc.sales_rank <= 10 THEN 'Top Customer'
        ELSE 'Regular Customer'
    END AS customer_type,
    ca.ca_city,
    ca.ca_state,
    (SELECT COUNT(1) FROM store s WHERE s.s_store_sk IN (SELECT DISTINCT sr.s_store_sk FROM store_returns sr WHERE sr.sr_ticket_number IN (SELECT DISTINCT ws.ws_order_number FROM web_sales ws WHERE ws.ws_ship_date_sk = (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2022) AND ws.ws_ship_mode_sk = sh.cs_ship_mode_sk)))
    AS return_count,
    COALESCE(ROUND(AVG(sh.cs_sales_price), 2), 0) AS avg_sales_price
FROM 
    top_customers tc
LEFT JOIN 
    customer_address ca ON tc.c_customer_id = ca.ca_address_id
JOIN 
    sales_hierarchy sh ON tc.total_sales = sh.cs_ext_sales_price
GROUP BY 
    tc.c_customer_id, tc.total_sales, ca.ca_city, ca.ca_state, tc.sales_rank
HAVING 
    total_sales > 1000
ORDER BY 
    total_sales DESC;
