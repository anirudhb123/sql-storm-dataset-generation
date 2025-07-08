
WITH RECURSIVE CustomerHierarchy AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        c_current_cdemo_sk,
        1 AS level
    FROM customer c
    WHERE c_current_cdemo_sk IS NOT NULL

    UNION ALL

    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        ch.c_current_cdemo_sk,
        ch.level + 1
    FROM customer c
    JOIN CustomerHierarchy ch ON c.c_current_cdemo_sk = ch.c_customer_sk
),
TotalSales AS (
    SELECT 
        ws_bill_customer_sk AS customer_sk,
        SUM(ws_net_paid_inc_tax) AS total_spent
    FROM web_sales
    GROUP BY ws_bill_customer_sk
),
HighValueCustomers AS (
    SELECT 
        ch.c_customer_sk,
        ch.c_first_name,
        ch.c_last_name,
        ts.total_spent,
        DENSE_RANK() OVER (ORDER BY ts.total_spent DESC) AS rank
    FROM CustomerHierarchy ch
    JOIN TotalSales ts ON ch.c_customer_sk = ts.customer_sk
    WHERE ts.total_spent IS NOT NULL
)
SELECT 
    hv.c_first_name,
    hv.c_last_name,
    hv.total_spent,
    CASE 
        WHEN hv.rank <= 10 THEN 'Top 10%'
        ELSE 'Others'
    END AS customer_rank_group,
    ca.ca_city,
    ca.ca_state,
    ca.ca_country
FROM HighValueCustomers hv
LEFT JOIN customer_address ca ON hv.c_customer_sk = ca.ca_address_sk
WHERE ca.ca_city IS NOT NULL
ORDER BY total_spent DESC, hv.c_last_name, hv.c_first_name
LIMIT 100;
