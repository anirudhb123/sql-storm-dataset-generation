
WITH RECURSIVE sales_summary AS (
    SELECT 
        ws_bill_customer_sk, 
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS order_count,
        ROW_NUMBER() OVER (PARTITION BY ws_bill_customer_sk ORDER BY SUM(ws_ext_sales_price) DESC) AS rank
    FROM web_sales
    WHERE ws_sold_date_sk IN (
        SELECT d_date_sk 
        FROM date_dim 
        WHERE d_year = 2023 AND d_month_seq BETWEEN 1 AND 3
    )
    GROUP BY ws_bill_customer_sk
), 
top_customers AS (
    SELECT 
        customer.c_customer_id, 
        customer.c_first_name, 
        customer.c_last_name, 
        sales.total_sales, 
        sales.order_count
    FROM customer 
    JOIN sales_summary sales ON customer.c_customer_sk = sales.ws_bill_customer_sk
    WHERE sales.rank <= 10
),
customer_demo AS (
    SELECT 
        cd_gender, 
        cd_marital_status, 
        COUNT(*) AS demographic_count
    FROM customer_demographics 
    WHERE cd_demo_sk IN (
        SELECT DISTINCT c_current_cdemo_sk
        FROM customer
        WHERE c_birth_year BETWEEN 1980 AND 1995
    )
    GROUP BY cd_gender, cd_marital_status
),
customer_address_info AS (
    SELECT 
        ca.city AS city_name, 
        COUNT(DISTINCT c.c_customer_id) AS customer_count
    FROM customer_address ca
    LEFT JOIN customer c ON ca.ca_address_sk = c.c_current_addr_sk
    GROUP BY ca.city
)
SELECT 
    tc.c_customer_id,
    tc.c_first_name,
    tc.c_last_name,
    tc.total_sales,
    cd.cd_gender,
    cd.cd_marital_status,
    cai.city_name, 
    cai.customer_count
FROM top_customers tc
LEFT JOIN customer_demo cd ON tc.c_customer_id = cd.cd_demo_sk
INNER JOIN customer_address_info cai ON tc.c_customer_id = cai.city_name
ORDER BY tc.total_sales DESC;
