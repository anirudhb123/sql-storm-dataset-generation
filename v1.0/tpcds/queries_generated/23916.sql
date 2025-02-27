
WITH RECURSIVE Address_CTE AS (
    SELECT ca_city, ca_state, COUNT(ca_address_sk) AS address_count
    FROM customer_address
    WHERE ca_city IS NOT NULL AND ca_state IS NOT NULL
    GROUP BY ca_city, ca_state
    HAVING COUNT(ca_address_sk) > 1
), 
Selected_Customers AS (
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, ca.ca_city, ca.ca_state
    FROM customer c
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    WHERE c.c_birth_year BETWEEN 1980 AND 1990
    AND c.c_preferred_cust_flag = 'Y'
), 
Promotion_Summary AS (
    SELECT p.p_promo_id, COUNT(DISTINCT ws.ws_order_number) AS sales_count,
           SUM(ws.ws_net_paid) AS total_sales
    FROM promotion p
    LEFT JOIN web_sales ws ON p.p_promo_sk = ws.ws_promo_sk
    GROUP BY p.p_promo_id
    HAVING SUM(ws.ws_net_paid) > 10000
)
SELECT 
    c.c_customer_sk, c.c_first_name, c.c_last_name, ac.address_count,
    ps.promo_id, ps.sales_count, ps.total_sales,
    COALESCE(ac.address_count, 0) AS calculated_address_count,
    CASE 
        WHEN ac.address_count IS NULL THEN 'No Address'
        WHEN ac.address_count > 10 THEN 'Multiple Addresses'
        ELSE 'Single Address'
    END AS address_category
FROM Selected_Customers c
FULL OUTER JOIN Address_CTE ac ON (c.ca_city = ac.ca_city AND c.ca_state = ac.ca_state)
FULL OUTER JOIN Promotion_Summary ps ON c.c_customer_sk = ps.promo_id 
WHERE (c.c_customer_sk IS NULL OR ps.sales_count IS NOT NULL)
AND (c.c_first_name LIKE '%a%' OR c.c_last_name LIKE '%b%')
ORDER BY c.c_last_name DESC NULLS LAST, ps.total_sales ASC
OFFSET 10 ROWS FETCH NEXT 20 ROWS ONLY;
