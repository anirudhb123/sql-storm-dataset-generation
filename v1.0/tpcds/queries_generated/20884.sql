
WITH RECURSIVE address_hierarchy AS (
    SELECT ca_address_sk, ca_city, ca_state, 1 AS level
    FROM customer_address
    WHERE ca_country = 'USA'
    UNION ALL
    SELECT ca.ca_address_sk, ca.ca_city, ca.ca_state, ah.level + 1
    FROM customer_address ca
    JOIN address_hierarchy ah ON ca.ca_address_sk = ah.ca_address_sk
    WHERE ca.ca_city IS NOT NULL
), sales_summary AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_net_paid) AS total_sales,
        COUNT(ws_order_number) AS order_count,
        AVG(ws_sales_price) AS avg_sales_price,
        MAX(ws_sales_price) AS max_sales_price
    FROM web_sales
    GROUP BY ws_bill_customer_sk
), demographic_analysis AS (
    SELECT 
        c.c_customer_id,
        cd.cd_gender,
        COALESCE(hd.hd_buy_potential, 'Unknown') AS purchase_potential,
        DENSE_RANK() OVER (PARTITION BY cd.cd_gender ORDER BY SUM(ss_net_profit) DESC) as gender_rank
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN store_sales ss ON ss.ss_customer_sk = c.c_customer_sk
    LEFT JOIN household_demographics hd ON c.c_customer_sk = hd.hd_demo_sk
    GROUP BY c.c_customer_id, cd.cd_gender, hd.hd_buy_potential
), join_sales AS (
    SELECT 
        d.c_customer_id,
        d.cd_gender,
        d.purchase_potential,
        COALESCE(ss.total_sales, 0) AS total_sales,
        ss.order_count,
        ss.avg_sales_price,
        ss.max_sales_price,
        CASE 
            WHEN d.gender_rank IS NOT NULL THEN 'Ranked'
            ELSE 'Unranked'
        END AS rank_status
    FROM demographic_analysis d
    LEFT JOIN sales_summary ss ON d.c_customer_id = ss.ws_bill_customer_sk
)
SELECT 
    j.c_customer_id,
    j.cd_gender,
    j.purchase_potential,
    j.total_sales,
    j.order_count,
    j.avg_sales_price,
    j.max_sales_price,
    CASE 
        WHEN j.total_sales > 1000 THEN 'High Value'
        ELSE 'Low Value'
    END AS customer_value_flag,
    ah.ca_city,
    ah.ca_state
FROM join_sales j
JOIN address_hierarchy ah ON j.c_customer_id = ah.ca_address_sk
LEFT JOIN (SELECT DISTINCT ws_bill_customer_sk FROM web_sales WHERE ws_net_profit IS NULL) AS no_profit ON j.c_customer_id = no_profit.ws_bill_customer_sk
WHERE j.order_count > 0
  AND (j.total_sales > 0 OR no_profit.ws_bill_customer_sk IS NOT NULL)
  AND ah.level < 3
ORDER BY j.total_sales DESC, j.c_customer_id
LIMIT 100;
