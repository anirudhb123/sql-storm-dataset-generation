
WITH RECURSIVE address_tree AS (
    SELECT ca_address_sk, ca_city, ca_state, ca_country
    FROM customer_address
    WHERE ca_state IS NOT NULL
    UNION ALL
    SELECT a.ca_address_sk, CONCAT(at.ca_city, ' -> ', a.ca_city), a.ca_state, a.ca_country
    FROM customer_address a
    INNER JOIN address_tree at ON a.ca_city = at.ca_city
    WHERE a.ca_state IS NOT NULL
), 
filtered_promotions AS (
    SELECT p.p_promo_sk, p.p_promo_name, p.p_discount_active,
           SUM(CASE WHEN p.p_discount_active = 'Y' THEN 1 ELSE 0 END) OVER (PARTITION BY p.p_promo_sk) AS active_count
    FROM promotion p
    WHERE p.p_cost > (SELECT AVG(p2.p_cost) FROM promotion p2)
), 
customer_info AS (
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, 
           COALESCE(cd.cd_gender, 'U') AS gender, 
           COALESCE(cd.cd_marital_status, 'N') AS marital_status,
           SUM(ws.ws_quantity) AS total_quantity
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status
), 
profitability AS (
    SELECT ws.ws_customer_sk,
           SUM(ws.ws_sales_price - ws.ws_ext_discount_amt) AS net_profit
    FROM web_sales ws
    GROUP BY ws.ws_customer_sk
    HAVING SUM(ws.ws_sales_price - ws.ws_ext_discount_amt) > 0
), 
item_statistics AS (
    SELECT i.i_item_id, AVG(ws.ws_sales_price) AS avg_price, 
           MAX(ws.ws_net_profit) AS max_profit,
           COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM item i
    JOIN web_sales ws ON i.i_item_sk = ws.ws_item_sk
    WHERE i.i_current_price IS NOT NULL
    GROUP BY i.i_item_id
), 
reason_summary AS (
    SELECT r.r_reason_sk, COUNT(DISTINCT sr_ticket_number) AS total_returns
    FROM store_returns sr
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    GROUP BY r.r_reason_sk
)
SELECT ca.ca_city, SUM(ci.total_quantity) AS customer_quantity, 
       it.avg_price, ps.active_count,
       COALESCE(rs.total_returns, 0) AS total_returns
FROM address_tree ca
LEFT JOIN customer_info ci ON ci.gender = 'M'
JOIN filtered_promotions ps ON ps.p_promo_sk = ci.c_customer_sk
LEFT JOIN item_statistics it ON it.order_count > 3
LEFT JOIN reason_summary rs ON rs.r_reason_sk = ci.c_customer_sk
GROUP BY ca.ca_city, it.avg_price, ps.active_count
HAVING COUNT(ci.c_customer_sk) > 2
ORDER BY customer_quantity DESC, ca.ca_city ASC;
