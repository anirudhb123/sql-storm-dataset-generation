
WITH RECURSIVE address_hierarchy AS (
    SELECT ca_address_sk, ca_city, ca_state, ca_country
    FROM customer_address
    WHERE ca_city IS NOT NULL AND ca_state IS NOT NULL
    UNION ALL
    SELECT a.ca_address_sk, a.ca_city, a.ca_state, a.ca_country
    FROM customer_address a
    INNER JOIN address_hierarchy h ON a.ca_address_sk = h.ca_address_sk
    WHERE a.ca_state <> h.ca_state
), 
sales_summary AS (
    SELECT 
        ss_store_sk,
        SUM(ss_sales_price) AS total_sales,
        COUNT(ss_ticket_number) AS transaction_count,
        RANK() OVER (PARTITION BY ss_store_sk ORDER BY SUM(ss_sales_price) DESC) AS revenue_rank
    FROM store_sales
    GROUP BY ss_store_sk
), 
customer_analysis AS (
    SELECT 
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS gender_rank
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
), 
ship_costs AS (
    SELECT 
        sm.ship_mode_sk,
        AVG(ws.ws_ext_ship_cost) AS avg_ship_cost,
        COUNT(*) AS total_shipments,
        CASE 
            WHEN AVG(ws.ws_ext_ship_cost) < 5 THEN 'Low'
            WHEN AVG(ws.ws_ext_ship_cost) BETWEEN 5 AND 10 THEN 'Medium'
            ELSE 'High'
        END AS shipping_cost_category
    FROM web_sales ws
    INNER JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    GROUP BY sm.ship_mode_sk
)
SELECT 
    s.s_store_name,
    sa.total_sales,
    ca.c_customer_id,
    ca.cd_gender,
    ca.cd_marital_status,
    ah.ca_city,
    ah.ca_state,
    sh.shipping_cost_category,
    sh.avg_ship_cost
FROM sales_summary sa
JOIN store s ON sa.ss_store_sk = s.s_store_sk
JOIN customer_analysis ca ON ca.gender_rank <= 5
JOIN address_hierarchy ah ON ca.c_customer_id LIKE CONCAT('%', ah.ca_city, '%')
JOIN ship_costs sh ON sh.ship_mode_sk = (SELECT sm_ship_mode_sk FROM ship_mode WHERE sm_code = 'Standard')
WHERE sa.transaction_count > 10
ORDER BY sa.total_sales DESC, ca.cd_purchase_estimate DESC
LIMIT 50;
