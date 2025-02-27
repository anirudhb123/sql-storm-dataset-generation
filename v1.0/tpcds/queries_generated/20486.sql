
WITH RECURSIVE CustomerHierarchy AS (
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, 
           cd.cd_gender, cd.cd_marital_status,
           ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY c.c_last_name) AS rn
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE cd.cd_marital_status IS NOT NULL
),
Promotions AS (
    SELECT p.p_promo_sk, p.p_promo_name, p.p_cost, 
           CASE 
               WHEN p.p_discount_active = 'Y' THEN 'Active'
               ELSE 'Inactive'
           END AS promo_status
    FROM promotion p
    WHERE p.p_start_date_sk < (SELECT MAX(d.d_date_sk) FROM date_dim d) 
      AND p.p_end_date_sk > (SELECT MIN(d.d_date_sk) FROM date_dim d)
),
SalesData AS (
    SELECT ws_item_sk, SUM(ws_sales_price) AS total_sales,
           AVG(ws_net_profit) AS avg_profit
    FROM web_sales 
    WHERE ws_sold_date_sk BETWEEN 1 AND 365
    GROUP BY ws_item_sk
)
SELECT ca.ca_city, ca.ca_state,
       COUNT(DISTINCT ch.c_customer_sk) AS distinct_customers,
       SUM(sd.total_sales) AS total_web_sales,
       ROUND(AVG(CASE WHEN ch.rn % 2 = 0 THEN sd.avg_profit END), 2) AS avg_profit_even_rn,
       STRING_AGG(DISTINCT p.promo_name || ' (' || p.promo_status || ')') AS active_promotions
FROM customer_address ca
LEFT OUTER JOIN CustomerHierarchy ch ON ca.ca_address_sk = ch.c_customer_sk
LEFT JOIN SalesData sd ON ch.c_customer_sk = sd.ws_item_sk
JOIN Promotions p ON p.p_promo_sk = (SELECT MAX(p2.p_promo_sk) FROM Promotions p2 
                                      WHERE p2.p_promo_name IS NOT NULL)
GROUP BY ca.ca_city, ca.ca_state
HAVING SUM(sd.total_sales) > 10000 AND COUNT(ch.c_customer_sk) > 5
ORDER BY ca.ca_state DESC, total_web_sales DESC
LIMIT 100 OFFSET (SELECT COUNT(*) FROM customer) / 2;
