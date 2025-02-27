
WITH RECURSIVE address_hierarchy AS (
    SELECT ca_address_sk, 
           ca_street_number, 
           ca_street_name, 
           ca_city, 
           ca_state, 
           ca_country,
           0 AS level
    FROM customer_address
    WHERE ca_city IS NOT NULL

    UNION ALL

    SELECT a.ca_address_sk, 
           a.ca_street_number, 
           a.ca_street_name, 
           a.ca_city, 
           a.ca_state, 
           a.ca_country,
           ah.level + 1
    FROM customer_address a
    JOIN address_hierarchy ah ON a.ca_city = ah.ca_city AND a.ca_state = ah.ca_state
    WHERE ah.level < 5
),
customer_summary AS (
    SELECT c.c_customer_sk,
           c.c_first_name,
           c.c_last_name,
           cd.cd_gender,
           cd.cd_marital_status,
           SUM(CASE WHEN cd.cd_marital_status = 'M' THEN 1 ELSE 0 END) OVER (PARTITION BY c.c_customer_sk) AS married_count,
           COUNT(DISTINCT ca.ca_address_sk) AS num_addresses,
           MAX(cd.cd_purchase_estimate) AS max_purchase_estimate,
           MIN(cd.cd_purchase_estimate) AS min_purchase_estimate
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status
),
sales_summary AS (
    SELECT ws_bill_customer_sk,
           SUM(ws_sales_price) AS total_sales,
           AVG(ws_net_profit) AS avg_net_profit
    FROM web_sales
    WHERE ws_sales_price > 0
    GROUP BY ws_bill_customer_sk
),
final_report AS (
    SELECT cs.c_customer_sk,
           cs.c_first_name,
           cs.c_last_name,
           coalesce(ss.total_sales, 0) AS total_sales,
           coalesce(ss.avg_net_profit, 0) AS avg_net_profit,
           ah.ca_city, 
           ah.ca_state, 
           ah.ca_country,
           CASE WHEN ah.level IS NOT NULL THEN 'In Address Hierarchy' ELSE 'Not in Hierarchy' END AS hierarchy_status
    FROM customer_summary cs
    LEFT JOIN sales_summary ss ON cs.c_customer_sk = ss.ws_bill_customer_sk
    LEFT JOIN address_hierarchy ah ON cs.c_customer_sk = ah.ca_address_sk
)
SELECT c.*,
       STRING_AGG( DISTINCT hierarchy_status, ', ' ORDER BY hierarchy_status) AS status_summary
FROM final_report c
GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name, total_sales, avg_net_profit, ah.ca_city, ah.ca_state, ah.ca_country
HAVING SUM(CASE WHEN c.total_sales > 500 THEN 1 ELSE 0 END) > 5
ORDER BY total_sales DESC
LIMIT 100 OFFSET 10;
