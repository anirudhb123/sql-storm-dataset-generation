
WITH RECURSIVE address_hierarchy AS (
    SELECT ca_address_sk, ca_address_id, 
           COALESCE(ca_city, 'Unknown') AS city,
           ROW_NUMBER() OVER (PARTITION BY COALESCE(ca_city, 'Unknown') ORDER BY ca_address_sk) AS rn
    FROM customer_address
    WHERE ca_country IS NOT NULL
    UNION ALL
    SELECT a.ca_address_sk, a.ca_address_id, 
           COALESCE(a.ca_city, 'Unknown'),
           ROW_NUMBER() OVER (PARTITION BY COALESCE(a.ca_city, 'Unknown') ORDER BY a.ca_address_sk)
    FROM customer_address a
    JOIN address_hierarchy b ON a.ca_address_sk = b.ca_address_sk + 1
    WHERE a.ca_state = 'CA'
),
customer_info AS (
    SELECT c.c_customer_sk,
           c.c_customer_id,
           cd.cd_gender,
           cd.cd_marital_status,
           cd.cd_purchase_estimate,
           SUM(ws.ws_quantity) AS total_quantity,
           COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE cd.cd_purchase_estimate IS NOT NULL
      AND (cd.cd_gender = 'F' OR cd.cd_gender IS NULL)
      AND (EXISTS (SELECT 1 
                   FROM store s 
                   WHERE s.s_city = 'Los Angeles' 
                     AND s.s_state = 'CA')
           OR cd.cd_marital_status IS NULL)
    GROUP BY c.c_customer_sk, c.c_customer_id, cd.cd_gender, cd.cd_marital_status, cd.cd_purchase_estimate
),
sales_summary AS (
    SELECT ws.ws_item_sk,
           SUM(ws.ws_sales_price) AS total_sales,
           AVG(ws.ws_sales_price) AS avg_sales_price,
           COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM web_sales ws
    WHERE ws.ws_ship_mode_sk IN (SELECT sm_ship_mode_sk FROM ship_mode WHERE sm_type LIKE '%Air%')
    GROUP BY ws.ws_item_sk
    HAVING SUM(ws.ws_sales_price) > 100.00
),
final_summary AS (
    SELECT ci.c_customer_id,
           ci.cd_gender,
           SUM(ss.total_sales) AS overall_sales,
           COUNT(ss.total_orders) AS total_order_count,
           (SELECT COUNT(*) FROM customer_info) AS total_customers,
           (SELECT COUNT(*) 
            FROM address_hierarchy 
            WHERE city = ci.city) AS address_count
    FROM customer_info ci
    JOIN sales_summary ss ON ci.c_customer_sk = ss.ws_item_sk
    GROUP BY ci.c_customer_id, ci.cd_gender
)
SELECT * 
FROM final_summary
WHERE (overall_sales IS NOT NULL OR total_order_count > 0)
  AND (cd_gender IS NULL OR cd_gender IN ('M', 'F'))
ORDER BY overall_sales DESC, total_order_count DESC
LIMIT 100;
