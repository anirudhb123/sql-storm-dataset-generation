
WITH AddressData AS (
    SELECT 
        ca_address_sk,
        CONCAT(ca_street_number, ' ', ca_suite_number, ' ', ca_street_name, ' ', ca_street_type, ', ', ca_city, ', ', ca_state, ' ', ca_zip, ', ', ca_country) AS full_address,
        LENGTH(CONCAT(ca_street_number, ' ', ca_suite_number, ' ', ca_street_name, ' ', ca_street_type, ', ', ca_city, ', ', ca_state, ' ', ca_zip, ', ', ca_country)) AS address_length
    FROM 
        customer_address
),
DemoData AS (
    SELECT 
        cd_demo_sk,
        CONCAT(cd_gender, '-', cd_marital_status, '-', cd_education_status) AS demographic_group,
        cd_purchase_estimate,
        cd_credit_rating
    FROM 
        customer_demographics
),
DateInfo AS (
    SELECT 
        d_date_sk,
        d_date,
        d_day_name,
        d_month_seq,
        d_year,
        d_fy_year,
        d_current_day,
        d_weekend
    FROM 
        date_dim
),
SalesData AS (
    SELECT 
        ws_sales_price,
        ws_net_profit,
        ws_item_sk,
        ws_order_number,
        DENSE_RANK() OVER (PARTITION BY ws_item_sk ORDER BY ws_net_profit DESC) AS profit_rank
    FROM 
        web_sales
)
SELECT 
    A.full_address, 
    D.demographic_group, 
    S.ws_sales_price, 
    S.ws_net_profit, 
    S.profit_rank,
    DATE_FORMAT(D.d_date, '%Y-%m-%d') as sale_date,
    MAX(A.address_length) AS max_address_length,
    COUNT(DISTINCT S.ws_order_number) AS total_orders,
    SUM(S.ws_net_profit) AS total_net_profit
FROM 
    AddressData A
JOIN 
    DemoData D ON A.ca_address_sk = D.cd_demo_sk
JOIN 
    DateInfo D ON D.d_date_sk = S.ws_sold_date_sk
JOIN 
    SalesData S ON S.ws_item_sk = A.ca_address_sk
GROUP BY 
    A.full_address, 
    D.demographic_group, 
    S.ws_sales_price, 
    S.ws_net_profit, 
    S.profit_rank,
    D.d_date
HAVING 
    SUM(S.ws_net_profit) > 1000
ORDER BY 
    max_address_length DESC, 
    total_orders ASC
LIMIT 100;
