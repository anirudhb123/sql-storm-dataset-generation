
WITH RECURSIVE customer_hierarchy AS (
    SELECT c_customer_sk, c_first_name, c_last_name, c_current_cdemo_sk, 1 AS level
    FROM customer
    WHERE c_current_cdemo_sk IS NOT NULL
    
    UNION ALL
    
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, c.c_current_cdemo_sk, ch.level + 1
    FROM customer c
    JOIN customer_hierarchy ch ON c.c_current_cdemo_sk = ch.c_customer_sk
),
address_stats AS (
    SELECT ca_state, COUNT(*) AS address_count
    FROM customer_address
    GROUP BY ca_state
),
demographic_income AS (
    SELECT cd_cd.cd_demo_sk, ib.ib_income_band_sk, 
           CASE 
               WHEN ib.ib_lower_bound IS NULL OR ib.ib_upper_bound IS NULL THEN 'Unknown'
               ELSE CONCAT('Income from ', ib.ib_lower_bound, ' to ', ib.ib_upper_bound)
           END AS income_band
    FROM customer_demographics cd_cd
    LEFT JOIN household_demographics hd ON cd_cd.cd_demo_sk = hd.hd_demo_sk
    LEFT JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
),
sales_summary AS (
    SELECT ws_bill_customer_sk, 
           SUM(ws_net_profit) AS total_profit,
           RANK() OVER (PARTITION BY ws_bill_customer_sk ORDER BY SUM(ws_net_profit) DESC) AS profit_rank
    FROM web_sales
    GROUP BY ws_bill_customer_sk
)
SELECT ch.c_first_name, ch.c_last_name, addr.ca_state, addr.address_count, 
       di.income_band, ss.total_profit
FROM customer_hierarchy ch
JOIN address_stats addr ON addr.ca_state = (SELECT ca_state FROM customer_address WHERE ca_address_sk = ch.c_current_addr_sk)
LEFT JOIN demographic_income di ON ch.c_current_cdemo_sk = di.cd_demo_sk
LEFT JOIN sales_summary ss ON ch.c_customer_sk = ss.ws_bill_customer_sk
WHERE ch.level = 1 AND (ss.total_profit > 500 OR ss.total_profit IS NULL)
ORDER BY addr.address_count DESC, ss.total_profit DESC
LIMIT 100;
