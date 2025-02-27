
WITH enriched_sales AS (
    SELECT 
        ws.ws_order_number,
        c.c_first_name || ' ' || c.c_last_name AS customer_name,
        ws.ws_sales_price,
        ws.ws_quantity,
        d.d_date AS sale_date,
        CASE 
            WHEN c.cd_gender = 'M' THEN 'Male'
            WHEN c.cd_gender = 'F' THEN 'Female'
            ELSE 'Other'
        END AS gender,
        COALESCE(SUBSTRING(c.c_email_address FROM POSITION('@' IN c.c_email_address) + 1 FOR 10), 'Unknown') AS email_domain,
        SUBSTRING(ca.ca_city FROM 1 FOR 10) AS city_short,
        RANK() OVER (PARTITION BY c.c_customer_sk ORDER BY ws.ws_sales_price DESC) AS price_rank
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year = 2023 
        AND ws.ws_sales_price > 50
)
SELECT 
    customer_name,
    SUM(ws_sales_price * ws_quantity) AS total_sales,
    COUNT(DISTINCT ws_order_number) AS order_count,
    AVG(ws_sales_price) AS avg_sales_price,
    COUNT(DISTINCT email_domain) AS unique_email_domains,
    STRING_AGG(city_short, ', ') AS unique_cities,
    MAX(price_rank) AS max_price_rank
FROM 
    enriched_sales
GROUP BY 
    customer_name
HAVING 
    total_sales > 500
ORDER BY 
    total_sales DESC
LIMIT 100;
