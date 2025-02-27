
WITH AddressDetails AS (
    SELECT
        ca.c_city,
        ca.ca_state,
        ca.ca_country,
        COUNT(DISTINCT c.c_customer_id) AS customer_count,
        STRING_AGG(DISTINCT CONCAT(c.c_first_name, ' ', c.c_last_name), ', ') AS customer_names
    FROM
        customer_address ca
    JOIN
        customer c ON ca.ca_address_sk = c.c_current_addr_sk
    GROUP BY
        ca.c_city, ca.ca_state, ca.ca_country
),
SalesData AS (
    SELECT
        d.d_year,
        SUM(ws.ws_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM
        web_sales ws
    JOIN
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    GROUP BY
        d.d_year
),
CustomerDemographics AS (
    SELECT
        cd.cd_gender,
        SUM(CASE WHEN cd.cd_marital_status = 'M' THEN cd.cd_purchase_estimate ELSE 0 END) AS total_married_spend,
        SUM(CASE WHEN cd.cd_marital_status = 'S' THEN cd.cd_purchase_estimate ELSE 0 END) AS total_single_spend
    FROM
        customer_demographics cd
    GROUP BY
        cd.cd_gender
)
SELECT
    AD.c_city,
    AD.ca_state,
    AD.ca_country,
    AD.customer_count,
    AD.customer_names,
    SD.d_year,
    SD.total_sales,
    SD.total_orders,
    CD.cd_gender,
    CD.total_married_spend,
    CD.total_single_spend
FROM
    AddressDetails AD
JOIN
    SalesData SD ON true
JOIN
    CustomerDemographics CD ON true
ORDER BY
    AD.c_city, AD.ca_state, AD.ca_country, SD.d_year;
