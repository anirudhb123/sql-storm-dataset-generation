
WITH RECURSIVE CustomerHierarchy AS (
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, c.c_birth_country, 
           0 AS level, c.c_preferred_cust_flag
    FROM customer c
    WHERE c.c_preferred_cust_flag = 'Y'
    
    UNION ALL
    
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, c.c_birth_country, 
           ch.level + 1, c.c_preferred_cust_flag
    FROM customer c
    JOIN CustomerHierarchy ch ON c.c_current_hdemo_sk = ch.c_customer_sk
),
AddressDetails AS (
    SELECT ca.ca_address_sk, 
           CONCAT(ca.ca_street_number, ' ', ca.ca_street_name, ' ', ca.ca_city, ', ', ca.ca_state, ' ', ca.ca_zip) AS full_address,
           ca.ca_country
    FROM customer_address ca
),
MonthlySales AS (
    SELECT d.d_month_seq, SUM(ws.ws_net_profit) AS total_profit, 
           COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    GROUP BY d.d_month_seq
),
SubqueryResults AS (
    SELECT ch.c_customer_sk, ch.c_first_name, ch.c_last_name, ch.c_birth_country, ad.full_address,
           ms.total_profit
    FROM CustomerHierarchy ch
    LEFT JOIN AddressDetails ad ON ch.c_customer_sk = ad.ca_address_sk
    LEFT JOIN MonthlySales ms ON ch.c_customer_sk = ms.d_month_seq
)
SELECT sr.return_item_sk, sr.return_quantity, sr.return_amt, sr.return_tax, 
       sr.return_amt_inc_tax, sr.store_credit, sr.net_loss, 
       sr.return_time_sk, ch.c_first_name, ch.c_last_name, 
       ch.full_address, ch.total_profit
FROM store_returns sr
LEFT JOIN SubqueryResults ch ON sr.sr_customer_sk = ch.c_customer_sk
WHERE ch.total_profit IS NOT NULL 
AND (sr.return_quantity > 1 OR sr.return_amt > 100.00)
ORDER BY sr.return_item_sk, ch.total_profit DESC;
