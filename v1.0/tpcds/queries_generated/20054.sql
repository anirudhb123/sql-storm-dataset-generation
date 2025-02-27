
WITH sales_summary AS (
    SELECT
        ws_bill_customer_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS total_orders,
        SUM(ws_quantity) AS total_quantity,
        RANK() OVER (PARTITION BY ws_bill_customer_sk ORDER BY SUM(ws_ext_sales_price) DESC) AS sales_rank
    FROM web_sales
    GROUP BY ws_bill_customer_sk
),
top_customers AS (
    SELECT
        c.c_customer_id,
        cs.ws_bill_customer_sk,
        cs.total_sales,
        cs.total_orders,
        cs.total_quantity
    FROM sales_summary cs
    JOIN customer c ON c.c_customer_sk = cs.ws_bill_customer_sk
    WHERE cs.sales_rank <= 10
),
address_info AS (
    SELECT
        ca.ca_address_sk,
        ca.ca_city,
        ca.ca_state,
        ca.ca_country,
        ROW_NUMBER() OVER (PARTITION BY ca.ca_city ORDER BY ca.ca_address_sk) AS city_rank
    FROM customer_address ca
),
customer_details AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_credit_rating,
        COALESCE(ab.total_orders, 0) AS total_orders,
        COALESCE(ab.total_sales, 0) AS total_sales,
        COALESCE(ab.total_quantity, 0) AS total_quantity,
        ai.ca_city,
        ai.ca_state
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN top_customers ab ON c.c_customer_sk = ab.ws_bill_customer_sk
    LEFT JOIN address_info ai ON ai.ca_address_sk = c.c_current_addr_sk
)
SELECT 
    cd.c_first_name,
    cd.c_last_name,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.cd_credit_rating,
    cd.total_orders,
    cd.total_sales,
    cd.total_quantity,
    ai.ca_city,
    ai.ca_state,
    CASE 
        WHEN cd.total_sales > 10000 THEN 'High Value'
        WHEN cd.total_sales BETWEEN 5000 AND 10000 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS customer_value_category
FROM customer_details cd
LEFT JOIN date_dim dd ON dd.d_date_sk = (SELECT MAX(d_date_sk) FROM date_dim WHERE d_current_year = 1)
WHERE cd.total_quantity > (SELECT AVG(total_quantity) FROM top_customers)
AND cd.cd_gender IS NOT NULL
ORDER BY cd.total_sales DESC
LIMIT 50
UNION
SELECT 
    NULL AS c_first_name,
    NULL AS c_last_name,
    NULL AS cd_gender,
    NULL AS cd_marital_status,
    NULL AS cd_credit_rating,
    COUNT(*) AS total_orders,
    SUM(ws_ext_sales_price) AS total_sales,
    SUM(ws_quantity) AS total_quantity,
    NULL AS ca_city,
    NULL AS ca_state,
    'Overall Summary' AS customer_value_category
FROM web_sales
WHERE ws_sold_date_sk = (
    SELECT MAX(ws_sold_date_sk)
    FROM web_sales
)
GROUP BY ws_bill_customer_sk;
