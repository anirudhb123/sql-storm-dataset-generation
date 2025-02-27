
WITH RECURSIVE sales_hierarchy AS (
    SELECT cs_bill_customer_sk, SUM(cs_net_profit) AS total_profit
    FROM catalog_sales
    GROUP BY cs_bill_customer_sk
    UNION ALL
    SELECT ws_bill_customer_sk, SUM(ws_net_profit) AS total_profit
    FROM web_sales
    GROUP BY ws_bill_customer_sk
),
customer_profits AS (
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name,
           COALESCE(sh.total_profit, 0) AS total_profit,
           CASE WHEN COALESCE(sh.total_profit, 0) > 1000 THEN 'High'
                WHEN COALESCE(sh.total_profit, 0) > 500 THEN 'Medium'
                ELSE 'Low' END AS profit_category
    FROM customer c
    LEFT JOIN sales_hierarchy sh ON c.c_customer_sk = sh.cs_bill_customer_sk
),
address_count AS (
    SELECT ca_customer_sk, COUNT(*) AS address_count
    FROM customer_address
    GROUP BY ca_customer_sk
),
final_report AS (
    SELECT cp.c_customer_sk, cp.c_first_name, cp.c_last_name,
           cp.total_profit, cp.profit_category,
           ac.address_count
    FROM customer_profits cp
    LEFT JOIN address_count ac ON cp.c_customer_sk = ac.ca_customer_sk
)
SELECT fr.c_customer_sk, fr.c_first_name, fr.c_last_name,
       fr.total_profit, fr.profit_category, 
       COALESCE(fr.address_count, 0) AS address_count,
       CASE 
           WHEN fr.profit_category = 'High' AND fr.address_count > 5 THEN 'Priority'
           WHEN fr.profit_category = 'Medium' OR fr.address_count BETWEEN 3 AND 5 THEN 'Standard'
           ELSE 'Review' 
       END AS customer_status
FROM final_report fr
ORDER BY fr.total_profit DESC, fr.c_last_name ASC;
