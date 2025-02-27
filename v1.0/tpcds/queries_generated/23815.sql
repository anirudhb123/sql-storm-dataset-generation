
WITH RECURSIVE AddressHierarchy AS (
    SELECT ca_address_sk, ca_city, ca_state, ca_country, ca_location_type, ca_address_id,
           ROW_NUMBER() OVER (PARTITION BY ca_city ORDER BY ca_address_sk) as rn
    FROM customer_address
    WHERE ca_city IS NOT NULL
    UNION ALL
    SELECT ca_address_sk, ca_city, ca_state, ca_country, ca_location_type, ca_address_id,
           rn + 1
    FROM customer_address ca
    JOIN AddressHierarchy ah ON ca.ca_state = ah.ca_state AND ca.rn = ah.rn + 1
),
CustomerMetrics AS (
    SELECT c.c_customer_id, c.c_first_name, c.c_last_name,
           MAX(cd.cd_purchase_estimate) as max_purchase_estimate,
           COUNT(DISTINCT w.ws_order_number) AS total_orders,
           SUM(w.ws_net_paid) AS total_revenue
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN web_sales w ON c.c_customer_sk = w.ws_bill_customer_sk
    GROUP BY c.c_customer_id, c.c_first_name, c.c_last_name
),
OrderStats AS (
    SELECT ws_bill_customer_sk, COUNT(*) AS order_count,
           AVG(ws_net_profit) AS avg_profit, SUM(ws_coupon_amt) AS total_coupon_discount
    FROM web_sales
    GROUP BY ws_bill_customer_sk
),
FinalReport AS (
    SELECT cm.c_customer_id,
           cm.c_first_name,
           cm.c_last_name,
           ah.ca_city,
           ah.ca_state,
           COALESCE(os.order_count, 0) AS order_count,
           COALESCE(os.avg_profit, 0) AS avg_profit,
           COALESCE(os.total_coupon_discount, 0) AS total_coupon_discount,
           cm.total_orders,
           cm.total_revenue,
           (SELECT COUNT(*) FROM customer WHERE c_birth_year > 1980 AND c_current_cdemo_sk IS NOT NULL) AS young_customers_count
    FROM CustomerMetrics cm
    JOIN AddressHierarchy ah ON ah.ca_address_id = cm.c_customer_id
    LEFT JOIN OrderStats os ON cm.c_customer_id = os.ws_bill_customer_sk
)
SELECT *
FROM FinalReport
WHERE (avg_profit > 100 AND total_orders > 5)
   OR (order_count > 10 AND total_coupon_discount IS NOT NULL)
   OR (total_revenue = (SELECT MAX(total_revenue) FROM FinalReport) AND young_customers_count > 50)
ORDER BY total_revenue DESC, c_last_name ASC;
