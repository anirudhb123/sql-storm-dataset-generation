
WITH RECURSIVE sales_hierarchy AS (
    SELECT 
        ws.bill_customer_sk AS customer_sk,
        SUM(ws.ext_sales_price) AS total_sales,
        COUNT(ws.order_number) AS order_count,
        ROW_NUMBER() OVER (PARTITION BY ws.bill_customer_sk ORDER BY SUM(ws.ext_sales_price) DESC) AS rank
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.bill_customer_sk = c.c_customer_sk
    WHERE 
        c.c_birth_year IS NOT NULL
    GROUP BY 
        ws.bill_customer_sk
),
top_customers AS (
    SELECT customer_sk, total_sales, order_count 
    FROM sales_hierarchy
    WHERE rank <= 10
),
address_details AS (
    SELECT 
        ca.ca_address_sk, 
        ca.ca_city,
        ca.ca_state,
        NULLIF(c.co_county, '') AS county_name,
        ROW_NUMBER() OVER (PARTITION BY ca.ca_city ORDER BY ca.ca_address_sk) AS city_rank
    FROM customer_address ca
    LEFT JOIN (SELECT DISTINCT ca_county FROM customer_address) c ON TRUE
),
sales_summary AS (
    SELECT
        tc.customer_sk,
        SUM(COALESCE(ws.net_profit, 0)) AS total_profit,
        AVG(ws.ext_sales_price) AS avg_order_value,
        COUNT(DISTINCT ws.order_number) AS sales_count
    FROM
        top_customers tc
    LEFT JOIN
        web_sales ws ON tc.customer_sk = ws.bill_customer_sk
    GROUP BY 
        tc.customer_sk
)
SELECT 
    ss.customer_sk,
    ad.county_name,
    ss.total_profit,
    ss.avg_order_value,
    ss.sales_count
FROM 
    sales_summary ss
LEFT JOIN 
    address_details ad ON ss.customer_sk = ad.ca_address_sk
WHERE 
    ad.city_rank <= 5
ORDER BY 
    ss.total_profit DESC
LIMIT 20;
