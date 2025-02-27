
WITH RECURSIVE address_hierarchy AS (
    SELECT ca_address_sk, ca_city, ca_state, ca_country, 1 AS level
    FROM customer_address
    WHERE ca_state IS NOT NULL

    UNION ALL

    SELECT ca.ca_address_sk, ca.ca_city, ca.ca_state, ca.ca_country, ah.level + 1
    FROM customer_address ca
    JOIN address_hierarchy ah ON ca.ca_state = ah.ca_state AND ca.ca_country = ah.ca_country
    WHERE ah.level < 5
),
customer_with_demographics AS (
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, d.cd_gender, d.cd_marital_status,
           CASE
               WHEN d.cd_credit_rating IS NULL THEN 'Unknown'
               ELSE d.cd_credit_rating
           END AS credit_rating,
           (SELECT COUNT(*) FROM store s WHERE s.s_state = 'CA') AS store_count,
           ROW_NUMBER() OVER (PARTITION BY d.cd_gender ORDER BY c.c_first_name) AS rn
    FROM customer c
    LEFT JOIN customer_demographics d ON c.c_current_cdemo_sk = d.cd_demo_sk
    WHERE d.cd_purchase_estimate > 1000
),
sales_summary AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_sales_price) AS total_sales,
        SUM(ws.ws_net_profit) AS total_profit,
        CASE 
            WHEN SUM(ws.ws_quantity) = 0 THEN NULL 
            ELSE SUM(ws.ws_net_profit) / NULLIF(SUM(ws.ws_quantity), 0)
        END AS profit_per_item
    FROM web_sales ws
    GROUP BY ws.ws_item_sk
),
final_report AS (
    SELECT ca.ca_city, ca.ca_state, ca.ca_country, COUNT(DISTINCT c.c_customer_sk) AS customer_count,
           SUM(ss.total_quantity) AS total_items_sold,
           AVG(ss.total_sales) AS avg_sales_value,
           MAX(ss.total_profit) AS max_profit,
           MIN(ss.total_profit) AS min_profit,
           STRING_AGG(CONCAT(c.c_first_name, ' ', c.c_last_name, ' - ', c.credit_rating), '; ') AS customer_names
    FROM address_hierarchy ca
    LEFT JOIN customer_with_demographics c ON c.c_customer_sk IN 
        (SELECT c_current_addr_sk FROM customer WHERE c_current_hdemo_sk IN 
            (SELECT hd_demo_sk FROM household_demographics WHERE hd_dep_count > 3))
    LEFT JOIN sales_summary ss ON ss.ws_item_sk IN 
        (SELECT ws_item_sk FROM web_sales WHERE ws_ship_date_sk > (SELECT MAX(d_date_sk) FROM date_dim WHERE d_current_month = 'Y'))
    WHERE ca.level > 0
    GROUP BY ca.ca_city, ca.ca_state, ca.ca_country
)
SELECT *
FROM final_report
WHERE customer_count > 10
ORDER BY total_items_sold DESC;
