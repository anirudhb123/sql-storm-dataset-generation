
WITH FilteredCustomers AS (
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status, cd.cd_education_status
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE cd.cd_marital_status = 'M' AND cd.cd_gender = 'F'
),
CustomerAddresses AS (
    SELECT ca.ca_address_sk, ca.ca_city, ca.ca_state, ca.ca_zip
    FROM customer_address ca
    JOIN FilteredCustomers fc ON ca.ca_address_sk = fc.c_customer_sk
),
TopCities AS (
    SELECT ca.ca_city, COUNT(*) AS customer_count
    FROM CustomerAddresses ca
    GROUP BY ca.ca_city
    ORDER BY customer_count DESC
    LIMIT 5
),
SalesData AS (
    SELECT ws.ws_ship_date_sk, ws.ws_quantity, ws.ws_sales_price, wa.w_warehouse_name
    FROM web_sales ws
    JOIN warehouse wa ON ws.ws_warehouse_sk = wa.w_warehouse_sk
    WHERE ws.ws_sales_price > 100
),
SalesSummary AS (
    SELECT DATE(d.d_date) AS sales_date, SUM(sd.ws_quantity) AS total_quantity, SUM(sd.ws_sales_price) AS total_sales
    FROM SalesData sd
    JOIN date_dim d ON sd.ws_ship_date_sk = d.d_date_sk
    GROUP BY DATE(d.d_date)
    ORDER BY sales_date
)
SELECT DISTINCT fc.c_first_name, fc.c_last_name, top.ca_city, top.customer_count, ss.sales_date, ss.total_quantity, ss.total_sales
FROM FilteredCustomers fc
JOIN TopCities top ON top.ca_city IN (SELECT ca.ca_city FROM CustomerAddresses ca WHERE ca.ca_address_sk = fc.c_customer_sk)
JOIN SalesSummary ss ON ss.total_quantity > 10
ORDER BY ss.total_sales DESC, top.customer_count DESC;
