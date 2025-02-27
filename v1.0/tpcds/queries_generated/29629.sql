
WITH AddressComponents AS (
    SELECT
        ca_address_sk,
        TRIM(CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type, ' ', COALESCE(ca_suite_number, ''))) AS full_address,
        ca_city,
        ca_state,
        ca_zip,
        ca_country
    FROM customer_address
),
CustomerDetails AS (
    SELECT
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        c.c_email_address,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating,
        cd.cd_dep_count,
        cd.cd_dep_employed_count,
        cd.cd_dep_college_count
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
SalesData AS (
    SELECT
        ws.ws_order_number,
        ws.ws_quantity,
        ws.ws_sales_price,
        s.s_store_name,
        s.s_state,
        w.w_warehouse_name,
        DATE(d.d_date) AS sale_date
    FROM web_sales ws
    JOIN store s ON ws.ws_store_sk = s.s_store_sk
    JOIN warehouse w ON s.s_warehouse_sk = w.w_warehouse_sk
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
)
SELECT
    cd.full_name,
    cd.c_email_address,
    ac.full_address,
    ac.ca_city,
    ac.ca_state,
    ac.ca_zip,
    ac.ca_country,
    SUM(sd.ws_sales_price * sd.ws_quantity) AS total_spent,
    COUNT(sd.ws_order_number) AS total_orders
FROM CustomerDetails cd
JOIN AddressComponents ac ON cd.c_customer_sk = ac.ca_address_sk
LEFT JOIN SalesData sd ON cd.c_customer_sk = sd.ws_bill_customer_sk
GROUP BY
    cd.full_name,
    cd.c_email_address,
    ac.full_address,
    ac.ca_city,
    ac.ca_state,
    ac.ca_zip,
    ac.ca_country
HAVING total_spent > 1000
ORDER BY total_spent DESC;
