
WITH CustomerSummary AS (
    SELECT c.c_customer_sk,
           c.c_first_name,
           c.c_last_name,
           cd.cd_gender,
           SUM(ss.ss_net_paid) AS total_spent,
           COUNT(DISTINCT ss.ss_ticket_number) AS purchase_count,
           ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY SUM(ss.ss_net_paid) DESC) AS rank_by_gender
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender
),
HighSpenders AS (
    SELECT c.c_customer_sk,
           cs.total_spent,
           cs.rank_by_gender
    FROM CustomerSummary cs
    JOIN customer c ON cs.c_customer_sk = c.c_customer_sk
    WHERE cs.total_spent IS NOT NULL AND cs.total_spent > (SELECT AVG(total_spent) FROM CustomerSummary) 
          AND cs.rank_by_gender <= 10
),
AddressAnalytics AS (
    SELECT ca.ca_address_sk,
           ca.ca_city,
           ca.ca_state,
           COALESCE(ROUND(SUM(CASE 
                WHEN cs.total_spent IS NOT NULL THEN cs.total_spent 
                ELSE 0 END), 2), 0) AS city_total_spent,
           COUNT(DISTINCT cs.c_customer_sk) AS active_customers
    FROM customer_address ca
    LEFT JOIN CustomerSummary cs ON cs.c_customer_sk IN (
        SELECT c.c_customer_sk 
        FROM customer c 
        WHERE c.c_current_addr_sk = ca.ca_address_sk
    )
    GROUP BY ca.ca_address_sk, ca.ca_city, ca.ca_state
    HAVING city_total_spent > (SELECT MAX(city_total_spent) FROM (
                                        SELECT ROUND(SUM(COALESCE(cs.total_spent, 0)), 2) AS city_total_spent
                                        FROM customer_address ca_sub
                                        LEFT JOIN CustomerSummary cs ON cs.c_customer_sk IN (
                                            SELECT c.c_customer_sk 
                                            FROM customer c 
                                            WHERE c.c_current_addr_sk = ca_sub.ca_address_sk
                                        )
                                        GROUP BY ca_sub.ca_address_sk
                                   ) AS subquery)
),
FinalReport AS (
    SELECT aa.ca_address_sk,
           aa.ca_city,
           aa.ca_state,
           aa.city_total_spent,
           aa.active_customers,
           (SELECT COUNT(DISTINCT ws.ws_order_number)
            FROM web_sales ws JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
            WHERE wp.wp_creation_date_sk < (SELECT d.d_date_sk 
                                              FROM date_dim d 
                                              WHERE d.d_year = EXTRACT(YEAR FROM CURRENT_DATE) 
                                              AND d.d_month_seq BETWEEN 1 AND 12)
            AND ws.ws_bill_customer_sk IN (SELECT c.c_customer_sk FROM customer c WHERE c.c_current_addr_sk = aa.ca_address_sk)) AS online_order_count
    FROM AddressAnalytics aa
)
SELECT fir.types,
       fir.total_orders,
       fir.avg_sales,
       NULLIF(fir.avg_sales, 0) AS normalized_avg_sales
FROM (SELECT fa.ca_city || ', ' || fa.ca_state AS types,
             COUNT(fa.active_customers) AS total_orders,
             AVG(fa.city_total_spent) AS avg_sales
      FROM FinalReport fa
      GROUP BY fa.ca_city, fa.ca_state) fir
ORDER BY fir.avg_sales DESC NULLS LAST;
