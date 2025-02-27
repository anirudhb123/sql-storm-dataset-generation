
WITH AddressData AS (
    SELECT 
        ca_address_id,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        ca_city,
        ca_state,
        ca_zip,
        ca_country
    FROM customer_address
),
CustomerData AS (
    SELECT 
        c_customer_id,
        CONCAT(c_first_name, ' ', c_last_name) AS full_name,
        cd_gender,
        cd_marital_status,
        cd_education_status,
        cd_purchase_estimate
    FROM customer
    JOIN customer_demographics ON c_current_cdemo_sk = cd_demo_sk
),
SalesData AS (
    SELECT 
        ws_order_number,
        ws_ext_sales_price,
        ws_net_profit,
        d_year,
        d_month_seq,
        d_day_name
    FROM web_sales
    JOIN date_dim ON ws_sold_date_sk = d_date_sk
),
CombinedData AS (
    SELECT 
        c.full_name,
        c.c_customer_id,
        a.full_address,
        s.ws_order_number,
        s.ws_ext_sales_price,
        s.ws_net_profit,
        s.d_year,
        s.d_month_seq,
        s.d_day_name
    FROM CustomerData c
    JOIN AddressData a ON TRUE
    JOIN SalesData s ON c.c_customer_id LIKE CONCAT('%', a.ca_zip, '%')
)
SELECT 
    d_year,
    d_month_seq,
    COUNT(DISTINCT c_customer_id) AS total_customers,
    SUM(ws_ext_sales_price) AS total_sales,
    AVG(ws_net_profit) AS avg_net_profit,
    FULL_TEXT_SEARCH(concat(full_name, ' ', full_address)) AS search_vector
FROM CombinedData
GROUP BY d_year, d_month_seq
ORDER BY d_year, d_month_seq;
