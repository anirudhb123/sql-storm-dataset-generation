
WITH RECURSIVE CustomerHierarchy AS (
    SELECT c_customer_sk, c_first_name, c_last_name, 1 AS level 
    FROM customer 
    WHERE c_customer_sk IN (SELECT DISTINCT sr_returning_customer_sk FROM store_returns)
    UNION ALL
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, ch.level + 1
    FROM customer c
    JOIN CustomerHierarchy ch ON c.c_customer_sk = ch.c_child_sk
), 
SalesTotals AS (
    SELECT ws_bill_customer_sk AS customer_sk, SUM(ws_net_paid_inc_tax) AS total_sales
    FROM web_sales
    GROUP BY ws_bill_customer_sk
),
AddressDetails AS (
    SELECT ca_address_sk, ca_city, ca_state, ca_country
    FROM customer_address
    WHERE ca_state IN ('CA', 'NY')
),
ShipmentDetails AS (
    SELECT sm.sm_type, COUNT(*) AS shipment_count
    FROM ship_mode sm
    LEFT JOIN web_sales ws ON sm.sm_ship_mode_sk = ws.ws_ship_mode_sk
    GROUP BY sm.sm_type
),
ReturnsOverview AS (
    SELECT sr_returning_customer_sk, SUM(sr_return_amt) AS total_returns
    FROM store_returns
    GROUP BY sr_returning_customer_sk
)
SELECT 
    ch.c_first_name,
    ch.c_last_name,
    ad.ca_city,
    ad.ca_state,
    ad.ca_country,
    COALESCE(st.total_sales, 0) AS total_sales,
    COALESCE(ro.total_returns, 0) AS total_returns,
    s.sm_type,
    s.shipment_count
FROM CustomerHierarchy ch
LEFT JOIN AddressDetails ad ON ch.c_customer_sk = ad.ca_address_sk
LEFT JOIN SalesTotals st ON ch.c_customer_sk = st.customer_sk
LEFT JOIN ReturnsOverview ro ON ch.c_customer_sk = ro.sr_returning_customer_sk
LEFT JOIN ShipmentDetails s ON s.sm_type IS NOT NULL
WHERE (st.total_sales > 1000 OR ro.total_returns > 500)
ORDER BY total_sales DESC, total_returns DESC;
