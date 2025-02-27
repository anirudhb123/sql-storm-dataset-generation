
WITH RECURSIVE customer_hierarchy AS (
    SELECT 
        c_customer_sk,
        c_first_name,
        c_last_name,
        c_birth_day,
        c_birth_month,
        c_birth_year,
        1 AS level
    FROM customer
    WHERE c_customer_sk IN (SELECT DISTINCT sr_customer_sk FROM store_returns WHERE sr_return_quantity > 0)
    
    UNION ALL
    
    SELECT 
        c.customer_sk,
        c.c_first_name,
        c.c_last_name,
        c.c_birth_day,
        c.c_birth_month,
        c.c_birth_year,
        ch.level + 1
    FROM customer_hierarchy ch
    JOIN customer c ON ch.c_customer_sk = c.c_current_hdemo_sk
)

SELECT 
    ca.ca_city,
    COUNT(DISTINCT cu.c_customer_sk) AS unique_customers,
    AVG(cd.cd_purchase_estimate) AS avg_purchase_estimate,
    MAX(cd.cd_credit_rating) AS highest_credit_rating,
    SUM(ws.ws_net_paid_inc_tax) AS total_net_paid,
    DENSE_RANK() OVER (ORDER BY SUM(ws.ws_net_paid_inc_tax) DESC) AS ranked_sales
FROM customer_address ca
LEFT JOIN customer cu ON cu.c_current_addr_sk = ca.ca_address_sk
LEFT JOIN customer_hierarchy ch ON cu.c_customer_sk = ch.c_customer_sk
LEFT JOIN customer_demographics cd ON cu.c_current_cdemo_sk = cd.cd_demo_sk
LEFT JOIN web_sales ws ON cu.c_customer_sk = ws.ws_bill_customer_sk
WHERE ca.ca_city IS NOT NULL
AND (ch.level = 1 OR cd.cd_marital_status = 'M')
GROUP BY ca.ca_city
HAVING COUNT(DISTINCT cu.c_customer_sk) > 10
ORDER BY total_net_paid DESC 
LIMIT 10;
