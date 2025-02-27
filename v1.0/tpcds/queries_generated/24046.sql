
WITH ranked_sales AS (
    SELECT 
        ws.customer_sk,
        SUM(ws.ext_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws.customer_sk ORDER BY SUM(ws.ext_sales_price) DESC) AS sales_rank
    FROM web_sales ws
    JOIN customer c ON ws.bill_customer_sk = c.c_customer_sk
    WHERE ws.sold_date_sk IN (
        SELECT d_date_sk 
        FROM date_dim 
        WHERE d_year = 2023 AND d_moy = 12 AND d_dow IN (1, 2, 3, 4, 5) -- Weekdays in December 2023
    )
    GROUP BY ws.customer_sk
),
top_customers AS (
    SELECT customer_sk
    FROM ranked_sales
    WHERE sales_rank <= 100
),
customer_with_details AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        ca.ca_city,
        ca.ca_state,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_credit_rating,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        SUM(ws.ws_ext_sales_price) AS total_sales
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE c.c_customer_sk IN (SELECT customer_sk FROM top_customers)
    GROUP BY c.c_customer_id, c.c_first_name, c.c_last_name, ca.ca_city, ca.ca_state, cd.cd_gender, cd.cd_marital_status, cd.cd_credit_rating
)
SELECT 
    c.customer_id,
    CONCAT(c.first_name, ' ', c.last_name) AS full_name,
    c.city,
    c.state,
    c.gender,
    c.marital_status,
    c.credit_rating,
    COALESCE(c.order_count, 0) AS order_count,
    COALESCE(c.total_sales, 0) AS total_sales,
    CASE 
        WHEN c.credit_rating = 'Excellent' THEN 'Top-tier'
        WHEN c.credit_rating = 'Good' THEN 'Mid-tier'
        ELSE 'Need Improvement'
    END AS customer_tier
FROM customer_with_details c
ORDER BY c.total_sales DESC
LIMIT 50;
