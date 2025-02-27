
WITH RECURSIVE demo_income AS (
    SELECT d.cd_demo_sk, 
           d.cd_gender, 
           d.cd_marital_status, 
           d.cd_education_status, 
           d.cd_purchase_estimate, 
           d.cd_credit_rating, 
           d.cd_dep_count,
           d.cd_dep_employed_count,
           d.cd_dep_college_count,
           CASE 
               WHEN d.cd_purchase_estimate < 100 THEN 'Low'
               WHEN d.cd_purchase_estimate BETWEEN 100 AND 500 THEN 'Medium'
               ELSE 'High'
           END AS income_category
    FROM customer_demographics d
),
high_income_customers AS (
    SELECT c.c_customer_id, 
           c.c_first_name, 
           c.c_last_name, 
           coi.in_home_delivery,
           coi.total_orders,
           ROW_NUMBER() OVER (PARTITION BY ci.income_category ORDER BY coi.total_orders DESC) as rank
    FROM customer c
    LEFT JOIN (
        SELECT c.c_customer_sk, 
               SUM(WS.ws_quantity) AS total_orders,
               CASE 
                   WHEN (ra.r_reason_desc IS NOT NULL OR ra.r_reason_desc LIKE '%discount%') THEN 1
                   ELSE 0
               END AS in_home_delivery
        FROM web_sales WS
        LEFT JOIN store_returns sr ON WS.ws_item_sk = sr.sr_item_sk
        LEFT JOIN reason ra ON sr.sr_reason_sk = ra.r_reason_sk
        JOIN demo_income di ON c.c_customer_sk = di.cd_demo_sk
        WHERE di.income_category = 'High'
        GROUP BY c.c_customer_sk
    ) coi ON c.c_customer_sk = coi.c_customer_sk
    WHERE coi.total_orders IS NOT NULL
),
ranked_customers AS (
    SELECT *, 
           COUNT(*) OVER(PARTITION BY in_home_delivery) as total_by_delivery
    FROM high_income_customers
)
SELECT r.c_customer_id, 
       r.c_first_name, 
       r.c_last_name, 
       r.in_home_delivery,
       r.total_orders,
       r.rank,
       r.total_by_delivery,
       COUNT(r.c_customer_id) OVER() AS total_customers,
       ARRAY_AGG(DISTINCT CONCAT(ca.ca_city, ', ', ca.ca_state)) AS delivery_cities
FROM ranked_customers r
LEFT JOIN customer_address ca ON r.c_customer_id = ca.ca_address_id
WHERE (r.in_home_delivery = 1 AND r.total_orders > 10) OR (r.in_home_delivery = 0 AND r.total_orders <= 10)
ORDER BY r.rank
LIMIT 50;
