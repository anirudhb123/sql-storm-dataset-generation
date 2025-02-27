
WITH address_info AS (
    SELECT 
        ca_county,
        ca_state,
        COUNT(ca_address_sk) AS address_count,
        STRING_AGG(DISTINCT ca_city, ', ') AS unique_cities
    FROM customer_address
    GROUP BY ca_county, ca_state
), 
customer_info AS (
    SELECT 
        cd_gender,
        cd_marital_status,
        COUNT(c_customer_sk) AS customer_count,
        SUM(cd_dep_count) AS total_dependents
    FROM customer 
    JOIN customer_demographics ON c_current_cdemo_sk = cd_demo_sk
    GROUP BY cd_gender, cd_marital_status
), 
sales_info AS (
    SELECT 
        SUM(ws_sales_price) AS total_sales,
        COUNT(ws_order_number) AS total_orders,
        ws_bill_addr_sk AS billing_address
    FROM web_sales
    GROUP BY ws_bill_addr_sk
)
SELECT 
    a.ca_state, 
    a.ca_county, 
    a.address_count, 
    a.unique_cities, 
    c.cd_gender, 
    c.cd_marital_status, 
    c.customer_count, 
    c.total_dependents, 
    s.total_sales, 
    s.total_orders
FROM address_info a 
JOIN customer_info c ON a.ca_county = c.cd_marital_status -- This is a dummy join condition for illustration
JOIN sales_info s ON a.ca_address_sk = s.billing_address
ORDER BY a.ca_state, a.ca_county, c.cd_gender;
