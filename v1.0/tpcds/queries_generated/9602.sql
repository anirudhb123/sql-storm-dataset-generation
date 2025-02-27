
WITH CustomerDetails AS (
    SELECT
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM
        customer c
    JOIN
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE
        d.d_year = 2023
    GROUP BY
        c.c_customer_id, cd.cd_gender, cd.cd_marital_status, cd.cd_education_status, cd.cd_purchase_estimate, cd.cd_credit_rating
),
AddressDetails AS (
    SELECT
        ca.ca_address_id,
        ca.ca_city,
        ca.ca_state,
        COUNT(DISTINCT c.c_customer_id) AS customer_count
    FROM
        customer c
    JOIN
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    GROUP BY
        ca.ca_address_id, ca.ca_city, ca.ca_state
),
SalesSummary AS (
    SELECT
        ca.ca_city,
        ca.ca_state,
        SUM(ws.ws_ext_sales_price) AS city_sales,
        SUM(ws.ws_quantity) AS city_quantity
    FROM
        web_sales ws
    JOIN
        customer_address ca ON ws.ws_bill_addr_sk = ca.ca_address_sk
    JOIN
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE
        d.d_year = 2023
    GROUP BY
        ca.ca_city, ca.ca_state
)
SELECT
    cd.c_customer_id,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.cd_education_status,
    cd.cd_purchase_estimate,
    cd.cd_credit_rating,
    ad.ca_city,
    ad.ca_state,
    ad.customer_count,
    ss.city_sales,
    ss.city_quantity
FROM
    CustomerDetails cd
JOIN
    AddressDetails ad ON cd.c_customer_id IN (SELECT c.c_customer_id FROM customer c WHERE c.c_current_addr_sk IN (SELECT ca.ca_address_sk FROM customer_address ca WHERE ca.ca_city = ad.ca_city AND ca.ca_state = ad.ca_state))
JOIN
    SalesSummary ss ON ad.ca_city = ss.ca_city AND ad.ca_state = ss.ca_state
ORDER BY
    cd.total_sales DESC
LIMIT 100;
