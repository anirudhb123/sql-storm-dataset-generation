
WITH RECURSIVE Customer_Hierarchy AS (
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_marital_status, 
           cd.cd_gender, cd.cd_dep_count, cd.cd_credit_rating, 1 AS level 
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE c.c_birth_year > 1980
    
    UNION ALL
    
    SELECT ch.c_customer_sk, ch.c_first_name, ch.c_last_name,
           cd.cd_marital_status, cd.cd_gender, cd.cd_dep_count, cd.cd_credit_rating, 
           ch.level + 1 
    FROM Customer_Hierarchy ch
    JOIN customer c ON ch.c_customer_sk = c.c_current_addr_sk
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
Customer_Sales AS (
    SELECT c.c_customer_sk, SUM(ss.ss_net_paid) AS total_net_paid, 
           COUNT(ss.ss_ticket_number) AS total_transactions
    FROM customer c
    LEFT JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY c.c_customer_sk
),
Sales_CTE AS (
    SELECT ch.c_customer_sk, ch.c_first_name, ch.c_last_name, 
           cs.total_net_paid, cs.total_transactions,
           ROW_NUMBER() OVER (PARTITION BY ch.c_gender ORDER BY cs.total_net_paid DESC) AS rank
    FROM Customer_Hierarchy ch
    JOIN Customer_Sales cs ON ch.c_customer_sk = cs.c_customer_sk
)
SELECT 
    c.c_first_name, 
    c.c_last_name, 
    CASE 
        WHEN c.total_net_paid IS NOT NULL THEN c.total_net_paid 
        ELSE 0 
    END AS net_paid,
    COALESCE(SUM(s.s_net_profit), 0) AS total_profit,
    DENSE_RANK() OVER (ORDER BY total_profit DESC) AS profit_rank,
    CASE 
        WHEN c.total_transactions > 10 THEN 'High Engagement' 
        ELSE 'Low Engagement' 
    END AS engagement_level
FROM Sales_CTE c
LEFT JOIN (
    SELECT ss.ss_customer_sk, SUM(ss.ss_net_profit) AS s_net_profit 
    FROM store_sales ss
    GROUP BY ss.ss_customer_sk
) s ON c.c_customer_sk = s.ss_customer_sk
GROUP BY c.c_first_name, c.c_last_name, c.total_net_paid, c.total_transactions
HAVING total_profit > 1000 OR (COUNT(*) > 5 AND total_profit IS NULL)
ORDER BY profit_rank, c.c_first_name;
