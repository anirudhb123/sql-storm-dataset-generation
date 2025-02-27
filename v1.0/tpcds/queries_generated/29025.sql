
WITH AddressInfo AS (
    SELECT cac.ca_address_sk, 
           cac.ca_street_name,
           cac.ca_city, 
           cac.ca_state, 
           cac.ca_country,
           CONCAT(COALESCE(cac.ca_street_number, ''), ' ', COALESCE(cac.ca_street_name, ''), ' ', COALESCE(cac.ca_city, ''), ', ', COALESCE(cac.ca_state, ''), ' ', COALESCE(cac.ca_zip, '')) AS full_address
    FROM customer_address cac
),
DemographicInfo AS (
    SELECT c.c_customer_sk, 
           c.c_first_name, 
           c.c_last_name, 
           cd.cd_gender, 
           cd.cd_marital_status,
           CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
SalesInfo AS (
    SELECT ws.ws_ship_date_sk,
           ws.ws_item_sk,
           SUM(ws.ws_quantity) AS total_quantity_sold,
           SUM(ws.ws_net_paid_inc_tax) AS total_sales_value
    FROM web_sales ws
    GROUP BY ws.ws_ship_date_sk, ws.ws_item_sk
),
ItemInfo AS (
    SELECT i.i_item_sk,
           i.i_item_desc,
           i.i_current_price
    FROM item i
)
SELECT di.full_name, 
       di.cd_gender, 
       di.cd_marital_status, 
       ai.full_address, 
       COUNT(si.ws_item_sk) AS items_sold,
       SUM(si.total_quantity_sold) AS total_items_sold,
       SUM(si.total_sales_value) AS total_sales_value,
       COUNT(DISTINCT si.ws_item_sk) AS distinct_items_sold
FROM DemographicInfo di
JOIN AddressInfo ai ON di.c_customer_sk = ai.ca_address_sk
JOIN SalesInfo si ON di.c_customer_sk = si.ws_bill_customer_sk
JOIN ItemInfo ii ON si.ws_item_sk = ii.i_item_sk
WHERE ai.ca_state = 'CA' AND di.cd_gender = 'F'
GROUP BY di.full_name, di.cd_gender, di.cd_marital_status, ai.full_address
ORDER BY total_sales_value DESC
LIMIT 100;
