
WITH RECURSIVE CustomerHierarchy AS (
    SELECT c.c_customer_sk, c.c_customer_id, c.c_salutation, c.c_first_name, c.c_last_name, 
           cd.cd_gender, cd.cd_marital_status, cd.cd_buy_potential, 0 AS level
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE cd.cd_marital_status = 'M'
    
    UNION ALL
    
    SELECT ch.c_customer_sk, ch.c_customer_id, ch.c_salutation, ch.c_first_name, ch.c_last_name, 
           ch.cd_gender, ch.cd_marital_status, ch.cd_buy_potential, level + 1
    FROM CustomerHierarchy ch
    JOIN customer c ON ch.c_customer_sk = c.c_current_hdemo_sk
)
SELECT 
    ch.c_customer_id,
    CONCAT(ch.c_salutation, ' ', ch.c_first_name, ' ', ch.c_last_name) AS full_name,
    ch.cd_gender,
    ch.cd_buy_potential,
    CASE 
        WHEN ch.level = 0 THEN 'Top Level Customer'
        WHEN ch.level = 1 THEN 'First Level Customer'
        ELSE 'Subsequent Level Customer'
    END AS customer_level,
    COUNT(DISTINCT s.ss_ticket_number) AS store_ticket_count,
    SUM(s.ss_net_profit) AS total_net_profit
FROM CustomerHierarchy ch
LEFT JOIN store_sales s ON s.ss_customer_sk = ch.c_customer_sk
GROUP BY ch.c_customer_id, ch.c_salutation, ch.c_first_name, ch.c_last_name, ch.cd_gender, ch.cd_buy_potential, ch.level
HAVING COUNT(DISTINCT s.ss_ticket_number) > 5
ORDER BY total_net_profit DESC
FETCH FIRST 10 ROWS ONLY;
