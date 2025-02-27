
WITH AddressStats AS (
    SELECT 
        ca_city, 
        ca_state, 
        COUNT(*) AS address_count, 
        ARRAY_AGG(DISTINCT ca_zip) AS unique_zip_codes
    FROM customer_address
    GROUP BY ca_city, ca_state
), 
CustomerStats AS (
    SELECT 
        cd_gender, 
        COUNT(*) AS customer_count, 
        AVG(cd_purchase_estimate) AS average_purchase_estimate
    FROM customer_demographics
    GROUP BY cd_gender
), 
WebSalesSummary AS (
    SELECT 
        ws_bill_addr_sk, 
        SUM(ws_net_paid) AS total_net_paid, 
        COUNT(ws_order_number) AS total_orders
    FROM web_sales
    GROUP BY ws_bill_addr_sk
)
SELECT 
    a.ca_city, 
    a.ca_state, 
    a.address_count, 
    ARRAY_LENGTH(a.unique_zip_codes) AS zip_code_count, 
    c.cd_gender, 
    c.customer_count, 
    c.average_purchase_estimate, 
    w.total_net_paid, 
    w.total_orders
FROM AddressStats a
JOIN CustomerStats c ON a.ca_state = c.cd_gender
JOIN WebSalesSummary w ON a.ca_address_sk = w.ws_bill_addr_sk
WHERE a.address_count > 10 
AND c.customer_count > 50
ORDER BY a.ca_city, c.cd_gender;
