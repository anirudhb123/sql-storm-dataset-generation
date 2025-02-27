
WITH RECURSIVE customer_rank AS (
    SELECT c.c_customer_sk,
           c.c_first_name,
           c.c_last_name,
           cd.cd_gender,
           cd.cd_marital_status,
           RANK() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS rank
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
sales_summary AS (
    SELECT ws.ws_bill_customer_sk AS customer_sk,
           SUM(ws.ws_sales_price) AS total_sales,
           COUNT(ws.ws_order_number) AS order_count
    FROM web_sales ws
    GROUP BY ws.ws_bill_customer_sk
),
promotional_sales AS (
    SELECT cs.cs_ship_mode_sk,
           SUM(cs.cs_net_profit) AS total_profit,
           COUNT(DISTINCT cs.cs_order_number) AS promo_order_count
    FROM catalog_sales cs
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    WHERE p.p_discount_active = 'Y'
    GROUP BY cs.cs_ship_mode_sk
)
SELECT ca.ca_city,
       COUNT(DISTINCT r.c_customer_sk) AS unique_customers,
       COALESCE(SUM(ss.total_sales), 0) AS total_sales,
       COALESCE(SUM(ps.total_profit), 0) AS total_promotional_profit,
       MAX(cr.rank) AS max_rank
FROM customer_address ca
LEFT JOIN customer_rank cr ON ca.ca_address_sk = (
    SELECT c.c_current_addr_sk
    FROM customer c
    WHERE c.c_customer_sk = r.c_customer_sk
)
LEFT JOIN sales_summary ss ON r.c_customer_sk = ss.customer_sk
LEFT JOIN promotional_sales ps ON ps.cs_ship_mode_sk IN (SELECT sm.sm_ship_mode_sk FROM ship_mode sm WHERE sm.sm_code = 'AIR' OR sm.sm_code = 'GROUND')
WHERE ca.ca_state IN ('CA', 'NY') AND (r.c_customer_sk IS NOT NULL OR r.c_customer_sk IS NULL)
GROUP BY ca.ca_city
HAVING COUNT(DISTINCT r.c_customer_sk) > (SELECT COUNT(DISTINCT c.c_customer_sk) / 100 FROM customer c)
ORDER BY unique_customers DESC;
