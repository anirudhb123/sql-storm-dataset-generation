
WITH RECURSIVE address_cte AS (
    SELECT ca_address_sk, ca_city, ca_country, ca_state, ca_zip, 
           CASE WHEN ca_street_number IS NOT NULL THEN 1 ELSE 0 END AS has_street_number
    FROM customer_address
    WHERE ca_country = 'USA'
    
    UNION ALL
    
    SELECT ca_address_sk, ca_city, ca_country, ca_state, ca_zip, 
           CASE WHEN ca_street_number IS NOT NULL THEN 1 ELSE 0 END AS has_street_number
    FROM customer_address a
    JOIN address_cte c ON a.ca_address_sk = c.ca_address_sk + 1
    WHERE a.ca_country = c.ca_country
)
SELECT 
    c.c_customer_id,
    COUNT(DISTINCT s.ss_ticket_number) AS num_transactions,
    SUM(s.ss_net_profit) AS total_net_profit,
    MAX(COALESCE(d.d_holiday, 'N')) AS holiday_status,
    STRING_AGG(DISTINCT CONCAT('City: ', ac.ca_city, ', State: ', ac.ca_state, ', Zip: ', ac.ca_zip), '; ') AS address_summary,
    DENSE_RANK() OVER (PARTITION BY c.c_country ORDER BY SUM(s.ss_net_prof) DESC) AS profit_rank
FROM customer c
LEFT JOIN store_sales s ON c.c_customer_sk = s.ss_customer_sk
LEFT JOIN address_cte ac ON c.c_current_addr_sk = ac.ca_address_sk
LEFT JOIN date_dim d ON d.d_date_sk = s.ss_sold_date_sk
WHERE 
    d.d_year = 2023
    AND c.c_birth_year IS NOT NULL
    AND (c.c_birth_month BETWEEN 1 AND 6 OR c.c_birth_day IS NOT NULL)
    AND (ac.has_street_number = 1 OR ac.ca_city IS NULL)
GROUP BY c.c_customer_id
HAVING 
    COUNT(DISTINCT s.ss_ticket_number) > 5
    OR SUM(s.ss_net_profit) > 1000
    OR MAX(ac.ca_country) = 'Canada'
ORDER BY total_net_profit DESC
FETCH FIRST 10 ROWS ONLY;
