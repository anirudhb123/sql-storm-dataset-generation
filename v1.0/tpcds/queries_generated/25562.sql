
WITH Customer_Info AS (
    SELECT
        c.c_customer_id,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        CONCAT(ca.ca_street_number, ' ', ca.ca_street_name, ' ', ca.ca_street_type, ', ', ca.ca_city, ', ', ca.ca_state, ' ', ca.ca_zip) AS full_address,
        ca.ca_country
    FROM
        customer c
    JOIN
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
Sales_Info AS (
    SELECT
        ws.ws_bill_customer_sk,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM
        web_sales ws
    GROUP BY
        ws.ws_bill_customer_sk
),
Combined_Info AS (
    SELECT
        ci.c_customer_id,
        ci.full_name,
        ci.cd_gender,
        si.total_sales,
        si.order_count
    FROM
        Customer_Info ci
    LEFT JOIN
        Sales_Info si ON ci.c_customer_id = si.ws_bill_customer_sk
)
SELECT 
    full_name,
    cd_gender,
    COALESCE(total_sales, 0) AS total_sales,
    COALESCE(order_count, 0) AS order_count,
    CASE 
        WHEN total_sales IS NULL THEN 'No Sales'
        WHEN total_sales < 100 THEN 'Low Spending'
        WHEN total_sales BETWEEN 100 AND 500 THEN 'Moderate Spending'
        ELSE 'High Spending'
    END AS spending_category
FROM
    Combined_Info
WHERE
    cd_gender = 'F'
ORDER BY 
    total_sales DESC
LIMIT 50;
