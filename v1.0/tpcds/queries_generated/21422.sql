
WITH RankedReturns AS (
    SELECT 
        sr_return_date_sk, 
        sr_item_sk,
        sr_return_quantity,
        ROW_NUMBER() OVER (PARTITION BY sr_item_sk ORDER BY sr_returned_date_sk DESC) AS rn
    FROM store_returns
    WHERE sr_return_quantity > 0
),
ProfitableItems AS (
    SELECT 
        ws_item_sk,
        SUM(ws_net_profit) AS total_profit
    FROM web_sales
    WHERE ws_sold_date_sk > (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2022)
    GROUP BY ws_item_sk
),
CustomerAddressWithLatLng AS (
    SELECT 
        ca_address_sk,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_city, ' ', ca_state, ' ', ca_zip) AS full_address,
        CASE
            WHEN ca_location_type IS NULL THEN 'Unknown'
            ELSE ca_location_type
        END AS address_type
    FROM customer_address
)
SELECT 
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    COALESCE(SUM(r.sr_return_quantity), 0) AS total_returns,
    COALESCE(SUM(pi.total_profit), 0) AS total_profit,
    CONCAT(CAW.full_address, ' - ', CAW.address_type) AS customer_location
FROM customer c
LEFT JOIN RankedReturns r ON c.c_customer_sk = r.sr_customer_sk
LEFT JOIN ProfitableItems pi ON r.sr_item_sk = pi.ws_item_sk
JOIN CustomerAddressWithLatLng CAW ON c.c_current_addr_sk = CAW.ca_address_sk
WHERE c.c_preferred_cust_flag = 'Y'
AND (c.c_birth_month IS NULL OR c.c_birth_month BETWEEN 1 AND 6)
GROUP BY c.c_customer_id, c.c_first_name, c.c_last_name, CAW.full_address, CAW.address_type
HAVING (total_returns > 5 OR total_profit > 1000)
ORDER BY total_profit DESC, total_returns DESC
LIMIT 50;
