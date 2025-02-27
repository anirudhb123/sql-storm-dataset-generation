
WITH RECURSIVE address_counts AS (
    SELECT ca_address_sk, ca_city, COUNT(c_customer_sk) AS customer_count
    FROM customer_address
    LEFT JOIN customer ON customer.c_current_addr_sk = customer_address.ca_address_sk
    GROUP BY ca_address_sk, ca_city
), promotion_summary AS (
    SELECT p_promo_id, COUNT(DISTINCT ws_order_number) AS total_sales
    FROM promotion
    JOIN web_sales ON promotion.p_promo_sk = web_sales.ws_promo_sk
    GROUP BY p_promo_id
), ranked_sales AS (
    SELECT ws_order_number, ws_net_paid_inc_tax,
           RANK() OVER (PARTITION BY ws_order_number ORDER BY ws_net_paid_inc_tax DESC) as rank
    FROM web_sales
    WHERE ws_net_paid_inc_tax IS NOT NULL
), item_prices AS (
    SELECT i_item_id, AVG(i_current_price) AS avg_price
    FROM item
    GROUP BY i_item_id
), customer_gender AS (
    SELECT cd_gender, avg_customer_value,
           CASE WHEN avg_customer_value > 1000 THEN 'Premium'
                ELSE 'Standard' END AS customer_classification
    FROM (
        SELECT c.c_customer_id, 
               SUM(ws.ws_net_paid) AS avg_customer_value,
               cd_gender
        FROM customer c
        JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk 
        JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
        GROUP BY c.c_customer_id, cd_gender
    ) AS sub
)
SELECT ca.ca_address_sk,
       ca.ca_city,
       ac.customer_count,
       ps.total_sales,
       rp.ws_order_number,
       rp.ws_net_paid_inc_tax,
       rp.rank,
       ip.avg_price,
       cg.cd_gender,
       cg.customer_classification
FROM customer_address AS ca
LEFT JOIN address_counts AS ac ON ca.ca_address_sk = ac.ca_address_sk
LEFT JOIN promotion_summary AS ps ON ps.total_sales > 0
LEFT JOIN ranked_sales AS rp ON rp.ws_order_number = ps.total_sales
LEFT JOIN item_prices AS ip ON ip.i_item_id = rp.ws_order_number::text 
LEFT JOIN customer_gender AS cg ON cg.cd_gender IS NOT NULL
WHERE ca.ca_city LIKE '%ville%'
AND (ac.customer_count IS NULL OR ac.customer_count > 10)
ORDER BY ca.ca_city, ps.total_sales DESC;
