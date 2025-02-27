
WITH CustomerInfo AS (
    SELECT
        c.c_customer_id,
        CONCAT(c.c_salutation, ' ', c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        ca.ca_city,
        ca.ca_state,
        ca.ca_country
    FROM
        customer c
    JOIN
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
), 
SalesSummary AS (
    SELECT
        ci.c_customer_id,
        SUM(ws.ws_ext_sales_price) AS total_spent,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM
        web_sales ws
    JOIN
        CustomerInfo ci ON ws.ws_bill_customer_sk = ci.c_customer_id
    GROUP BY
        ci.c_customer_id
)
SELECT
    ci.full_name,
    ci.cd_gender,
    ci.cd_marital_status,
    ci.cd_education_status,
    ci.ca_city,
    ci.ca_state,
    ci.ca_country,
    ss.total_spent,
    ss.total_orders
FROM
    CustomerInfo ci
LEFT JOIN
    SalesSummary ss ON ci.c_customer_id = ss.c_customer_id
WHERE
    ci.cd_gender = 'F' 
    AND ss.total_spent > 1000
ORDER BY
    ss.total_spent DESC;
