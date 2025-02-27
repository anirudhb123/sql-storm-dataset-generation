
WITH RECURSIVE customer_sales_cte AS (
    SELECT 
        c.c_customer_sk,
        c.c_customer_id,
        COALESCE(SUM(ws.ws_ext_sales_price), 0) AS total_web_sales,
        COALESCE(SUM(cs.cs_ext_sales_price), 0) AS total_catalog_sales,
        COALESCE(SUM(ss.ss_ext_sales_price), 0) AS total_store_sales
    FROM customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    LEFT JOIN catalog_sales cs ON c.c_customer_sk = cs.cs_ship_customer_sk
    LEFT JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY c.c_customer_sk, c.c_customer_id
),
ranked_sales AS (
    SELECT 
        c.customer_id, 
        c.total_web_sales + c.total_catalog_sales + c.total_store_sales AS total_sales,
        RANK() OVER (ORDER BY c.total_web_sales + c.total_catalog_sales + c.total_store_sales DESC) AS sales_rank
    FROM customer_sales_cte c
),
top_customers AS (
    SELECT 
        customer_id, 
        total_sales
    FROM ranked_sales
    WHERE sales_rank <= 10
),
customer_addresses AS (
    SELECT 
        ca.ca_address_sk,
        ca.ca_city,
        ca.ca_state,
        ca.ca_zip,
        ca.ca_country,
        tc.customer_id,
        tc.total_sales
    FROM customer_address ca
    JOIN top_customers tc ON tc.customer_id = ca.ca_address_sk
)
SELECT 
    ta.customer_id,
    ta.total_sales,
    ca.ca_city,
    ca.ca_state,
    ca.ca_zip,
    ca.ca_country,
    CASE 
        WHEN ta.total_sales IS NULL THEN 'No Sales'
        WHEN ta.total_sales < 1000 THEN 'Low Sales'
        WHEN ta.total_sales BETWEEN 1000 AND 5000 THEN 'Moderate Sales'
        ELSE 'High Sales'
    END AS sales_category
FROM customer_addresses ca
FULL OUTER JOIN top_customers ta ON ca.customer_id = ta.customer_id
WHERE 
    (ca.ca_city IS NOT NULL OR ca.ca_state IS NOT NULL OR ca.ca_zip IS NOT NULL) 
    AND (ta.total_sales IS NOT NULL OR ta.total_sales > 0)
ORDER BY ta.total_sales DESC, ca.ca_city;
