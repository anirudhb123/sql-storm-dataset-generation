
WITH RECURSIVE address_hierarchy AS (
    SELECT ca_address_sk, ca_address_id, ca_city, ca_state, NULL AS parent_id
    FROM customer_address
    WHERE ca_state = 'CA'
    UNION ALL
    SELECT ca.ca_address_sk, ca.ca_address_id, ca.ca_city, ca.ca_state, ah.ca_address_sk
    FROM customer_address ca
    JOIN address_hierarchy ah ON ca.ca_city = ah.ca_city AND ca.ca_state = ah.ca_state
    WHERE ca.ca_address_sk != ah.ca_address_sk
), 
customer_sales AS (
    SELECT 
        c.c_customer_sk, 
        SUM(ws.ws_net_paid) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY SUM(ws.ws_net_paid) DESC) AS sale_rank
    FROM customer c
    JOIN web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    GROUP BY c.c_customer_sk
), 
demographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        SUM(cs.cs_net_profit) AS total_profit
    FROM customer_demographics cd
    LEFT JOIN store_sales cs ON cd.cd_demo_sk = c.c_current_cdemo_sk
    JOIN customer c ON cd.cd_demo_sk = c.c_current_cdemo_sk
    GROUP BY cd.cd_demo_sk, cd.cd_gender, cd.cd_marital_status
), 
sales_metrics AS (
    SELECT 
        ch.ca_city,
        ch.ca_state,
        SUM(cs.total_sales) AS total_customer_sales,
        AVG(cs.total_sales) AS avg_customer_sales,
        COUNT(DISTINCT cs.c_customer_sk) AS unique_customers,
        CASE 
            WHEN SUM(cs.total_sales) > 100000 THEN 'High Sales'
            WHEN SUM(cs.total_sales) BETWEEN 50000 AND 100000 THEN 'Medium Sales'
            ELSE 'Low Sales'
        END AS sales_category
    FROM customer_sales cs
    JOIN address_hierarchy ch ON cs.c_customer_sk = ch.ca_address_sk
    GROUP BY ch.ca_city, ch.ca_state
)
SELECT 
    sm.sm_type AS shipping_method,
    COUNT(ss.ss_ticket_number) AS total_sales,
    SUM(ss.ss_net_profit) AS total_net_profit,
    AVG(ss.ss_net_profit) AS avg_net_profit,
    CASE
        WHEN SUM(ss.ss_net_profit) IS NULL THEN 'No Profit'
        WHEN SUM(ss.ss_net_profit) < 0 THEN 'Loss'
        ELSE 'Profit'
    END AS profit_status
FROM store_sales ss
JOIN ship_mode sm ON ss.ss_item_sk = sm.sm_ship_mode_sk
LEFT JOIN sales_metrics smt ON smt.sales_category = CASE 
    WHEN SUM(ss.ss_net_profit) > 100000 THEN 'High Sales'
    ELSE 'Other'
END
GROUP BY sm.sm_type
ORDER BY total_sales DESC
LIMIT 10;
