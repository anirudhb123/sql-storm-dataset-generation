
WITH RECURSIVE CustomerCTE AS (
    SELECT c_customer_sk, c_first_name, c_last_name, cd_demo_sk, 1 AS level
    FROM customer
    JOIN customer_demographics ON c_current_cdemo_sk = cd_demo_sk
    WHERE cd_gender = 'F'
    
    UNION ALL
    
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_demo_sk, level + 1
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN CustomerCTE cc ON c.c_customer_sk = cc.c_customer_sk
    WHERE c.c_birth_year > 2000
)
SELECT 
    c.c_customer_id,
    ca.ca_city,
    LISTAGG(DISTINCT CONCAT(cp.cp_description, ' (', cp.cp_type, ')'), ', ') WITHIN GROUP (ORDER BY cp.cp_description) AS catalog_pages,
    SUM(ws.ws_sales_price) AS total_spent,
    COUNT(ws.ws_order_number) AS total_orders,
    ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY SUM(ws.ws_sales_price) DESC) AS rank_by_spending
FROM customer c
LEFT JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
LEFT JOIN catalog_page cp ON ws.ws_web_page_sk = cp.cp_catalog_page_sk
WHERE ca.ca_city IS NOT NULL
AND (c.c_birth_year < 1980 OR c.c_birth_country IS NULL)
AND EXISTS (
    SELECT 1 
    FROM store_sales ss 
    WHERE ss.ss_customer_sk = c.c_customer_sk 
    AND ss.ss_sold_date_sk > (
        SELECT MAX(d.d_date_sk)
        FROM date_dim d
        WHERE d.d_year = 2023
    )
) 
GROUP BY c.c_customer_id, ca.ca_city, c.c_customer_sk
HAVING SUM(ws.ws_sales_price) > (
    SELECT AVG(total_spent)
    FROM (
        SELECT SUM(ws.ws_sales_price) AS total_spent
        FROM web_sales ws
        GROUP BY ws.ws_bill_customer_sk
    ) AS avg_spending
)
ORDER BY total_orders DESC
LIMIT 10;
