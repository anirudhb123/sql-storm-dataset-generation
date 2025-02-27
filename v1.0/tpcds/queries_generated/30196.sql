
WITH RECURSIVE sales_cte AS (
    SELECT 
        ws_item_sk, 
        SUM(ws_sales_price) AS total_sales, 
        COUNT(ws_order_number) AS order_count,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_sales_price) DESC) AS rank
    FROM web_sales
    WHERE ws_sold_date_sk >= (SELECT MAX(d_date_sk) - 30 FROM date_dim)
    GROUP BY ws_item_sk
),
address_cte AS (
    SELECT 
        ca_address_sk,
        ca_city,
        ca_state,
        ROW_NUMBER() OVER (PARTITION BY ca_state ORDER BY COUNT(ca_address_sk) DESC) AS city_rank
    FROM customer_address
    GROUP BY ca_address_sk, ca_city, ca_state
)
SELECT 
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    c.c_email_address,
    a.ca_city,
    a.ca_state,
    s.total_sales,
    s.order_count
FROM customer c
JOIN customer_address a ON c.c_current_addr_sk = a.ca_address_sk
LEFT JOIN sales_cte s ON s.ws_item_sk IN (SELECT ws_item_sk FROM web_sales WHERE ws_bill_customer_sk = c.c_customer_sk)
JOIN address_cte aa ON a.ca_address_sk = aa.ca_address_sk AND aa.city_rank <= 3
WHERE 
    c.c_birth_month = 5 AND 
    c.c_birth_day BETWEEN 15 AND 31 
    AND s.rank <= 10
    AND aa.ca_state IN (SELECT DISTINCT x.ca_state FROM address_cte x WHERE x.city_rank < 5)
ORDER BY s.total_sales DESC, c.c_last_name, c.c_first_name;
