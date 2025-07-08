
WITH RECURSIVE DateHierarchy AS (
    SELECT d_date_sk, 
           d_date,
           d_year, 
           d_month_seq,
           d_week_seq,
           d_dow,
           d_moy,
           d_dom,
           d_fy_year,
           d_current_day,
           d_current_month,
           1 AS level
    FROM date_dim
    WHERE d_date = (SELECT MAX(d_date) FROM date_dim)
    
    UNION ALL
    
    SELECT d.d_date_sk, 
           d.d_date,
           d.d_year, 
           d.d_month_seq,
           d.d_week_seq,
           d.d_dow,
           d.d_moy,
           d.d_dom,
           d.d_fy_year,
           d.d_current_day,
           d.d_current_month,
           level + 1
    FROM date_dim d
    JOIN DateHierarchy dh ON d.d_date_sk = dh.d_date_sk - 1
    WHERE level < 10
),
CustomerInfo AS (
    SELECT c.c_customer_sk,
           c.c_first_name,
           c.c_last_name,
           cd.cd_gender,
           cd.cd_marital_status,
           cd.cd_purchase_estimate,
           cd.cd_credit_rating,
           ca.ca_city,
           ca.ca_state,
           SUM(COALESCE(ws.ws_net_paid, 0)) AS total_spent
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status, 
             cd.cd_purchase_estimate, cd.cd_credit_rating, ca.ca_city, ca.ca_state
),
HighestSpender AS (
    SELECT c.c_customer_sk,
           c.c_first_name,
           c.c_last_name,
           MAX(c.total_spent) AS max_spent
    FROM CustomerInfo c
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name
),
RankedCustomers AS (
    SELECT c.*, 
           RANK() OVER (ORDER BY c.total_spent DESC) AS rank
    FROM CustomerInfo c
)
SELECT dk.d_year,
       dk.d_month_seq,
       dc.c_first_name,
       dc.c_last_name,
       dc.ca_city,
       dc.ca_state,
       dc.total_spent,
       COALESCE(hs.max_spent, 0) AS max_spending_amount,
       CASE 
           WHEN dc.total_spent IS NULL THEN 'No Purchases'
           WHEN dc.total_spent < 100 THEN 'Low Spender'
           WHEN dc.total_spent BETWEEN 100 AND 500 THEN 'Medium Spender'
           ELSE 'High Spender'
       END AS spending_category
FROM DateHierarchy dk
FULL OUTER JOIN RankedCustomers dc ON dk.d_year = dc.rank
LEFT JOIN HighestSpender hs ON dc.c_customer_sk = hs.c_customer_sk
WHERE dk.d_current_month = 'Y'
ORDER BY dk.d_year DESC, total_spent DESC
LIMIT 100;
