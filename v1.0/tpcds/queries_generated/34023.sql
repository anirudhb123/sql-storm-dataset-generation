
WITH RECURSIVE sales_hierarchy AS (
    SELECT 
        cs_bill_customer_sk AS customer_id,
        SUM(cs_net_profit) AS total_profit,
        COUNT(cs_order_number) AS order_count,
        1 AS level
    FROM catalog_sales
    WHERE cs_sold_date_sk BETWEEN 2400 AND 2450
    GROUP BY cs_bill_customer_sk
    UNION ALL
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_net_profit) + SH.total_profit AS total_profit,
        COUNT(ws_order_number) + SH.order_count AS order_count,
        SH.level + 1
    FROM web_sales WS
    JOIN sales_hierarchy SH ON WS.ws_bill_customer_sk = SH.customer_id
    WHERE WS.ws_sold_date_sk BETWEEN 2400 AND 2450
    GROUP BY ws_bill_customer_sk
),
customer_details AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        sh.total_profit,
        sh.order_count
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN sales_hierarchy sh ON c.c_customer_sk = sh.customer_id
),
address_info AS (
    SELECT 
        ca.ca_address_sk,
        ca.ca_city,
        ca.ca_state,
        COUNT(DISTINCT c.c_customer_id) AS customer_count
    FROM customer_address ca
    JOIN customer c ON c.c_current_addr_sk = ca.ca_address_sk
    GROUP BY ca.ca_address_sk, ca.ca_city, ca.ca_state
)
SELECT 
    ca.ca_city,
    ca.ca_state,
    ai.customer_count,
    AVG(cd.total_profit) AS avg_profit,
    SUM(cd.order_count) AS total_orders,
    COUNT(DISTINCT cd.c_customer_sk) FILTER (WHERE cd.cd_gender = 'F') AS female_customers,
    COUNT(DISTINCT cd.c_customer_sk) FILTER (WHERE cd.cd_gender = 'M') AS male_customers,
    COALESCE(MAX(cd.cd_purchase_estimate), 0) AS max_purchase_estimate
FROM address_info ai
JOIN customer_details cd ON ai.customer_count > 0
JOIN customer_address ca ON ca.ca_address_sk = cd.c_current_addr_sk
GROUP BY ca.ca_city, ca.ca_state 
HAVING SUM(cd.total_profit) > 1000
ORDER BY avg_profit DESC, total_orders DESC
LIMIT 10;
