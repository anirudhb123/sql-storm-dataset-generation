
WITH RECURSIVE CustomerHierarchy AS (
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, c.c_birth_year, 
           ca.ca_city, ca.ca_state, hd.hd_income_band_sk,
           ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY c.c_birth_year) AS rn
    FROM customer c
    LEFT JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    LEFT JOIN household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
    WHERE hd.hd_income_band_sk IS NOT NULL
    
    UNION ALL
    
    SELECT ch.c_customer_sk, ch.c_first_name, ch.c_last_name, ch.c_birth_year,
           ch.ca_city, ch.ca_state, ch.hd_income_band_sk,
           ROW_NUMBER() OVER (PARTITION BY ch.c_customer_sk ORDER BY ch.c_birth_year) AS rn
    FROM CustomerHierarchy ch
    JOIN customer_address ca ON ch.c_customer_sk = ca.ca_address_sk
    WHERE ch.rn < 3
),
Promotions AS (
    SELECT p.p_promo_id, p.p_start_date_sk, p.p_end_date_sk, 
           COUNT(cs.cs_order_number) AS total_sales
    FROM promotion p
    LEFT JOIN catalog_sales cs ON p.p_promo_sk = cs.cs_promo_sk
    GROUP BY p.p_promo_id, p.p_start_date_sk, p.p_end_date_sk
),
SalesStatistics AS (
    SELECT ws.ws_sold_date_sk, SUM(ws.ws_ext_sales_price) AS total_sales,
           COUNT(DISTINCT ws.ws_order_number) AS order_count,
           MAX(ws.ws_net_profit) AS max_profit,
           AVG(ws.ws_net_paid) AS avg_payment
    FROM web_sales ws
    WHERE ws.ws_sold_date_sk IN (SELECT d.d_date_sk 
                                  FROM date_dim d 
                                  WHERE d.d_year = 2023)
    GROUP BY ws.ws_sold_date_sk
)
SELECT ch.c_first_name, ch.c_last_name, ch.ca_city, ch.ca_state, 
       ps.total_sales, ss.total_sales, ss.order_count,
       ch.c_birth_year,
       CASE 
           WHEN ss.avg_payment IS NULL THEN 'No Payments'
           ELSE CAST(ss.avg_payment AS VARCHAR)
       END AS avg_payment_status
FROM CustomerHierarchy ch
LEFT JOIN Promotions ps ON ps.total_sales > 100
FULL OUTER JOIN SalesStatistics ss ON ch.c_customer_sk = ss.ws_sold_date_sk
WHERE ch.c_birth_year < 1980
ORDER BY ch.ca_state, ss.total_sales DESC
LIMIT 100;
