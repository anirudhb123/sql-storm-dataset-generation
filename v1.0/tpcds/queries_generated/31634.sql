
WITH RECURSIVE AddressHierarchy AS (
    SELECT ca_address_sk, ca_address_id, ca_street_number, ca_street_name, ca_city, ca_state
    FROM customer_address
    WHERE ca_state = 'CA'
    UNION ALL
    SELECT a.ca_address_sk, a.ca_address_id, a.ca_street_number, a.ca_street_name, a.ca_city, a.ca_state
    FROM customer_address a
    INNER JOIN AddressHierarchy h ON a.ca_city = h.ca_city AND a.ca_state = h.ca_state
),
CustomerPurchases AS (
    SELECT c.c_customer_sk, COUNT(ws.ws_order_number) AS total_orders, SUM(ws.ws_sales_price) AS total_spent
    FROM customer c
    JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY c.c_customer_sk
),
CustomerStats AS (
    SELECT c.c_customer_sk,
           COALESCE(d.cd_gender, 'Unknown') AS gender,
           COALESCE(d.cd_marital_status, 'U') AS marital_status,
           COALESCE(d.cd_credit_rating, 'Not Rated') AS credit_rating,
           COALESCE(p.total_orders, 0) AS total_orders,
           COALESCE(p.total_spent, 0) AS total_spent,
           CASE
               WHEN COALESCE(p.total_spent, 0) > 1000 THEN 'High Value'
               WHEN COALESCE(p.total_spent, 0) BETWEEN 500 AND 1000 THEN 'Medium Value'
               ELSE 'Low Value'
           END AS customer_value
    FROM customer c
    LEFT JOIN customer_demographics d ON c.c_current_cdemo_sk = d.cd_demo_sk
    LEFT JOIN CustomerPurchases p ON c.c_customer_sk = p.c_customer_sk
),
WarehouseStatistics AS (
    SELECT w_warehouse_sk, w_warehouse_name, AVG(w_warehouse_sq_ft) AS avg_warehouse_size
    FROM warehouse
    GROUP BY w_warehouse_sk, w_warehouse_name
)
SELECT a.ca_address_id,
       s.s_store_name,
       c.gender,
       c.marital_status,
       c.credit_rating,
       c.total_orders,
       c.total_spent,
       w.avg_warehouse_size,
       ROW_NUMBER() OVER (PARTITION BY c.customer_value ORDER BY c.total_spent DESC) AS order_rank
FROM AddressHierarchy a
JOIN store s ON a.ca_city = s.s_city AND a.ca_state = s.s_state
JOIN CustomerStats c ON a.ca_address_sk = c.c_customer_sk
JOIN WarehouseStatistics w ON w.w_warehouse_name = s.s_store_name
WHERE c.gender IS NOT NULL
  AND (c.total_orders > 0 OR c.total_spent > 0)
ORDER BY c.total_spent DESC, w.avg_warehouse_size ASC;
