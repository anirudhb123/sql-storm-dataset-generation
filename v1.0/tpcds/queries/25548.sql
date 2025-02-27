
WITH AddressData AS (
    SELECT 
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type, 
               COALESCE(CONCAT(' ', ca_suite_number), ''), 
               ', ', ca_city, ', ', ca_state, ' ', ca_zip) AS full_address,
        ca_country,
        ca_address_sk
    FROM 
        customer_address
), 
CustomerData AS (
    SELECT 
        CONCAT(c_first_name, ' ', c_last_name) AS full_name,
        cd_gender,
        cd_marital_status,
        cd_credit_rating,
        cd_purchase_estimate,
        c_customer_sk
    FROM 
        customer
    JOIN 
        customer_demographics ON c_current_cdemo_sk = cd_demo_sk
), 
SalesData AS (
    SELECT 
        ws_sales_price, 
        ws_ext_sales_price, 
        ws_net_profit, 
        ws_order_number,
        ws_ship_customer_sk
    FROM 
        web_sales
    WHERE 
        ws_sales_price > 50
)
SELECT 
    ad.full_address,
    cd.full_name,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.cd_credit_rating,
    COUNT(sd.ws_order_number) AS total_orders,
    SUM(sd.ws_net_profit) AS total_profit
FROM 
    AddressData ad
JOIN 
    SalesData sd ON ad.ca_address_sk = (SELECT c_current_addr_sk FROM customer WHERE c_customer_sk = sd.ws_ship_customer_sk)
JOIN 
    CustomerData cd ON cd.c_customer_sk = sd.ws_ship_customer_sk
GROUP BY 
    ad.full_address, cd.full_name, cd.cd_gender, cd.cd_marital_status, cd.cd_credit_rating
ORDER BY 
    total_profit DESC
LIMIT 100;
