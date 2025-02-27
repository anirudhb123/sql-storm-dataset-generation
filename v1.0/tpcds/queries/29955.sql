
WITH processed_addresses AS (
    SELECT 
        ca_address_sk,
        TRIM(UPPER(CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type))) AS full_address,
        ca_city,
        ca_state,
        ca_zip
    FROM customer_address
),
customer_sales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_ext_sales_price) AS total_sales
    FROM customer c
    JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name
),
address_sales AS (
    SELECT 
        pa.full_address,
        cs.c_customer_sk,
        cs.c_first_name,
        cs.c_last_name,
        cs.total_sales
    FROM processed_addresses pa
    JOIN customer_sales cs ON cs.c_customer_sk = (
        SELECT c.c_customer_sk
        FROM customer_address ca
        JOIN customer c ON ca.ca_address_sk = c.c_current_addr_sk
        WHERE pa.ca_address_sk = ca.ca_address_sk
        LIMIT 1
    )
)
SELECT 
    full_address,
    c_first_name,
    c_last_name,
    total_sales,
    CASE 
        WHEN total_sales > 1000 THEN 'High Value Customer'
        WHEN total_sales BETWEEN 500 AND 1000 THEN 'Medium Value Customer'
        ELSE 'Low Value Customer'
    END AS customer_value_category
FROM address_sales
ORDER BY total_sales DESC;
