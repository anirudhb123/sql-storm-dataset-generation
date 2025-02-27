
WITH FilteredCustomers AS (
    SELECT c_customer_sk, c_first_name, c_last_name, c_email_address, cd_gender, cd_marital_status
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE cd_gender = 'F' AND cd_marital_status = 'M'
),
CustomerAddresses AS (
    SELECT ca.ca_address_sk, ca.ca_city, ca.ca_state, ca.ca_zip
    FROM customer_address ca
    JOIN FilteredCustomers fc ON ca.ca_address_sk = fc.c_customer_sk
),
SalesData AS (
    SELECT ws.web_site_sk, SUM(ws.ws_sales_price) AS total_sales
    FROM web_sales ws
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    WHERE c.c_birth_year BETWEEN 1980 AND 1990
    GROUP BY ws.web_site_sk
),
TopCities AS (
    SELECT ca.ca_city, COUNT(*) AS customer_count
    FROM CustomerAddresses ca
    GROUP BY ca.ca_city
    ORDER BY customer_count DESC
    LIMIT 5
)
SELECT 
    fc.c_first_name,
    fc.c_last_name,
    fc.c_email_address,
    ca.ca_city,
    ca.ca_state,
    ca.ca_zip,
    sd.total_sales,
    tc.customer_count
FROM FilteredCustomers fc
JOIN CustomerAddresses ca ON ca.ca_address_sk = fc.c_customer_sk
JOIN SalesData sd ON fc.c_customer_sk = sd.web_site_sk
JOIN TopCities tc ON ca.ca_city = tc.ca_city
ORDER BY tc.customer_count DESC, sd.total_sales DESC;
