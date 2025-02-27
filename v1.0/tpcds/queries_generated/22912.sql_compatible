
WITH RECURSIVE address_cte AS (
    SELECT ca_address_sk, ca_city, ca_state, ca_country,
           ROW_NUMBER() OVER (PARTITION BY ca_city ORDER BY ca_address_sk) AS rn
    FROM customer_address
    WHERE ca_country = 'USA'
),
demographics AS (
    SELECT cd_gender, cd_marital_status, 
           SUM(cd_purchase_estimate) AS total_purchase_estimate,
           COUNT(cd_demo_sk) AS demographic_count
    FROM customer_demographics
    GROUP BY cd_gender, cd_marital_status
),
latest_sales AS (
    SELECT ws_item_sk, SUM(ws_quantity) AS total_quantity_sold,
           MAX(ws_net_paid) AS max_net_paid
    FROM web_sales
    WHERE ws_sold_date_sk >= (SELECT MAX(d_date_sk) 
                               FROM date_dim 
                               WHERE d_year = 2023)
    GROUP BY ws_item_sk
),
combined_sales AS (
    SELECT ss.ss_item_sk, ss.ss_ticket_number, 
           ss.ss_sales_price, ls.total_quantity_sold, 
           COALESCE(ls.max_net_paid, 0) AS max_net_paid_web
    FROM store_sales ss
    LEFT JOIN latest_sales ls ON ss.ss_item_sk = ls.ws_item_sk
)
SELECT a.ca_city, a.ca_state,
       d.cd_gender, d.cd_marital_status,
       SUM(cs.ss_net_profit + cs.max_net_paid_web) AS total_profit,
       COUNT(DISTINCT cs.ss_ticket_number) AS unique_sales
FROM address_cte a
LEFT JOIN combined_sales cs ON cs.ss_item_sk IN (
    SELECT DISTINCT i_item_sk
    FROM item
    WHERE i_current_price > 20 AND i_brand_id IS NOT NULL
)
INNER JOIN demographics d ON d.demographic_count > 0
WHERE a.rn <= 5
GROUP BY a.ca_city, a.ca_state, d.cd_gender, d.cd_marital_status
HAVING SUM(cs.ss_net_profit + cs.max_net_paid_web) IS NOT NULL
ORDER BY total_profit DESC, a.ca_state, a.ca_city;
