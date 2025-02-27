
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
CustomerInfo AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS customer_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
SalesData AS (
    SELECT 
        ws.web_site_sk,
        ws.ws_order_number,
        ws.ws_quantity,
        ws.ws_net_profit,
        dp.d_year,
        dp.d_month_seq
    FROM web_sales ws
    JOIN date_dim dp ON ws.ws_sold_date_sk = dp.d_date_sk
)
SELECT 
    ac.ca_city,
    ac.ca_state,
    COUNT(DISTINCT ci.c_customer_sk) AS unique_customers,
    SUM(sd.ws_net_profit) AS total_net_profit,
    AVG(ci.cd_purchase_estimate) AS avg_purchase_estimate,
    STRING_AGG(DISTINCT ci.customer_name, ', ') AS customer_names,
    STRING_AGG(DISTINCT ac.full_address, '; ') AS addresses
FROM AddressComponents ac
JOIN CustomerInfo ci ON ci.c_customer_sk IN (
    SELECT DISTINCT ws.ws_bill_customer_sk
    FROM SalesData sd JOIN web_sales ws ON sd.ws_order_number = ws.ws_order_number
)
WHERE ac.ca_state = 'CA' -- Focus on California addresses
GROUP BY ac.ca_city, ac.ca_state
ORDER BY total_net_profit DESC
LIMIT 10;
