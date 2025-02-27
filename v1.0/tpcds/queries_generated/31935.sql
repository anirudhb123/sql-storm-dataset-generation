
WITH RECURSIVE sales_hierarchy AS (
    SELECT 
        c.c_customer_sk, 
        c.c_first_name, 
        c.c_last_name, 
        ws.ws_sales_price AS sales_price,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY ws.ws_sold_date_sk DESC) AS rn
    FROM customer c
    JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE ws.ws_sold_date_sk BETWEEN 20220101 AND 20221231
    UNION ALL
    SELECT 
        sh.c_customer_sk, 
        sh.c_first_name, 
        sh.c_last_name, 
        ws.ws_sales_price AS sales_price,
        ROW_NUMBER() OVER (PARTITION BY sh.c_customer_sk ORDER BY ws.ws_sold_date_sk DESC) AS rn
    FROM sales_hierarchy sh
    JOIN web_sales ws ON sh.c_customer_sk = ws.ws_ship_customer_sk
    WHERE sh.rn < 5  
),
max_sales AS (
    SELECT 
        c.c_customer_sk, 
        MAX(ws.ws_sales_price) AS max_sale
    FROM customer c
    JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY c.c_customer_sk
),
address_info AS (
    SELECT 
        ca.ca_address_sk,
        ca.ca_city, 
        ca.ca_state, 
        COUNT(c.c_customer_sk) AS customer_count
    FROM customer_address ca
    LEFT JOIN customer c ON c.c_current_addr_sk = ca.ca_address_sk
    GROUP BY ca.ca_address_sk, ca.ca_city, ca.ca_state
    HAVING COUNT(c.c_customer_sk) > 10
)
SELECT 
    ch.c_first_name, 
    ch.c_last_name, 
    ch.sales_price,
    ms.max_sale,
    ai.ca_city, 
    ai.ca_state, 
    ai.customer_count
FROM sales_hierarchy ch
JOIN max_sales ms ON ch.c_customer_sk = ms.c_customer_sk
LEFT JOIN address_info ai ON ch.c_customer_sk = ai.ca_address_sk
WHERE ms.max_sale > 100
ORDER BY ai.customer_count DESC, ch.sales_price DESC
FETCH FIRST 100 ROWS ONLY;
