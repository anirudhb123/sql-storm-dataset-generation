
WITH AddressDetails AS (
    SELECT
        ca.city,
        ca.state,
        COUNT(DISTINCT c.c_customer_sk) AS customer_count,
        SUM(CASE WHEN cd_gender = 'F' THEN 1 ELSE 0 END) AS female_customers,
        SUM(CASE WHEN cd_marital_status = 'M' THEN 1 ELSE 0 END) AS married_customers
    FROM
        customer_address ca
    JOIN
        customer c ON ca.ca_address_sk = c.c_current_addr_sk
    JOIN
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY
        ca.city, ca.state
),
SalesDetails AS (
    SELECT
        ws.ws_ship_date_sk,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM
        web_sales ws
    GROUP BY
        ws.ws_ship_date_sk
),
CombinedData AS (
    SELECT
        ad.city,
        ad.state,
        ad.customer_count,
        ad.female_customers,
        ad.married_customers,
        sd.total_sales,
        sd.order_count
    FROM
        AddressDetails ad
    LEFT JOIN
        SalesDetails sd ON ad.city = (SELECT city FROM customer_address WHERE ca_address_sk = c.c_current_addr_sk) 
)
SELECT
    city,
    state,
    customer_count,
    female_customers,
    married_customers,
    COALESCE(SUM(total_sales), 0) AS total_sales_revenue,
    COALESCE(SUM(order_count), 0) AS total_order_count
FROM
    CombinedData
GROUP BY
    city, state, customer_count, female_customers, married_customers
ORDER BY
    total_sales_revenue DESC, city;
