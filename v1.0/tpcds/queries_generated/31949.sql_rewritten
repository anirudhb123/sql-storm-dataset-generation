WITH RECURSIVE SalesHierarchy AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        COALESCE(ss.ss_net_paid, 0) AS total_spent,
        1 AS level
    FROM customer c
    LEFT JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    WHERE ss.ss_sold_date_sk IS NOT NULL

    UNION ALL

    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        COALESCE(ss.ss_net_paid, 0) + COALESCE(parent.total_spent, 0) AS total_spent,
        parent.level + 1
    FROM customer c
    JOIN SalesHierarchy parent ON c.c_customer_sk = parent.c_customer_sk
    LEFT JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    WHERE ss.ss_sold_date_sk IS NOT NULL
)

SELECT 
    c.c_customer_sk,
    c.c_first_name,
    c.c_last_name,
    SUM(ss.ss_quantity) AS total_items_sold,
    AVG(ss.ss_net_paid) AS avg_spent_per_transaction,
    COUNT(DISTINCT ss.ss_ticket_number) AS transaction_count,
    RANK() OVER (ORDER BY SUM(ss.ss_net_paid) DESC) AS spending_rank,
    CASE 
        WHEN SUM(ss.ss_net_paid) > 1000 THEN 'High Spender'
        WHEN SUM(ss.ss_net_paid) BETWEEN 500 AND 1000 THEN 'Medium Spender'
        ELSE 'Low Spender'
    END AS spending_category
FROM customer c
LEFT JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
WHERE cd.cd_gender = 'F' 
   OR cd.cd_marital_status = 'S'
GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name
HAVING COUNT(DISTINCT ss.ss_ticket_number) > 2
ORDER BY AVG(ss.ss_net_paid) DESC
LIMIT 10;