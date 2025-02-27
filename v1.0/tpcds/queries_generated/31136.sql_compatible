
WITH RECURSIVE SalesHierarchy AS (
    SELECT ws_bill_customer_sk, SUM(ws_net_profit) AS total_profit
    FROM web_sales
    WHERE ws_sold_date_sk >= (
        SELECT MIN(d_date_sk)
        FROM date_dim
        WHERE d_year = 2023
    )
    GROUP BY ws_bill_customer_sk
    
    UNION ALL
    
    SELECT s.ss_customer_sk, SUM(s.ss_net_profit)
    FROM store_sales s
    JOIN SalesHierarchy sh ON sh.ws_bill_customer_sk = s.ss_customer_sk
    GROUP BY s.ss_customer_sk
),
CustomerDetails AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        sh.total_profit,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY sh.total_profit DESC) AS rank
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN SalesHierarchy sh ON c.c_customer_sk = sh.ws_bill_customer_sk
    WHERE cd.cd_marital_status IS NOT NULL
      AND cd.cd_credit_rating IS NOT NULL
),
TopCustomers AS (
    SELECT c.c_customer_id, c.c_first_name, c.c_last_name, c.total_profit
    FROM CustomerDetails c
    WHERE c.rank <= 10
)
SELECT 
    tc.c_customer_id,
    tc.c_first_name,
    tc.c_last_name,
    COALESCE(tc.total_profit, 0) AS total_profit,
    (SELECT COUNT(*) 
     FROM web_returns wr
     WHERE wr.returning_customer_sk = tc.c_customer_id) AS total_web_returns,
    (SELECT COUNT(*) 
     FROM store_returns sr
     WHERE sr.returning_customer_sk = tc.c_customer_id) AS total_store_returns
FROM TopCustomers tc
LEFT JOIN customer_address ca ON ca.ca_address_sk = (
    SELECT c.c_current_addr_sk
    FROM customer c
    WHERE c.c_customer_id = tc.c_customer_id
)
WHERE ca.ca_state IS NOT NULL
ORDER BY total_profit DESC;
