
WITH RECURSIVE sales_summary AS (
    SELECT 
        ws.bill_customer_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws.bill_customer_sk ORDER BY SUM(ws.ws_sales_price) DESC) AS rank
    FROM web_sales ws
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    WHERE c.c_birth_year BETWEEN 1980 AND 1990
    GROUP BY ws.bill_customer_sk
    HAVING SUM(ws.ws_sales_price) > 1000
), customer_details AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        ca.ca_city,
        ca.ca_state
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
), ranked_customers AS (
    SELECT 
        cd.full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        cd.ca_city,
        cd.ca_state,
        ss.total_quantity,
        ss.total_sales,
        ss.rank
    FROM customer_details cd
    JOIN sales_summary ss ON cd.c_customer_sk = ss.bill_customer_sk
)
SELECT 
    rc.full_name,
    rc.cd_gender,
    rc.cd_marital_status,
    rc.total_quantity,
    rc.total_sales,
    COALESCE(NULLIF(rc.total_sales, 0), 1) / NULLIF(rc.total_quantity, 0) AS price_per_unit, 
    CASE 
        WHEN rc.total_sales > 5000 THEN 'High spender'
        WHEN rc.total_sales BETWEEN 1000 AND 5000 THEN 'Medium spender'
        ELSE 'Low spender'
    END AS spending_category
FROM ranked_customers rc
WHERE rc.rank <= 10
ORDER BY rc.total_sales DESC;
