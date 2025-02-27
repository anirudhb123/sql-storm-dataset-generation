
WITH RECURSIVE sales_cte AS (
    SELECT ss_store_sk, ss_item_sk, SUM(ss_quantity) AS total_quantity, SUM(ss_net_paid) AS total_sales
    FROM store_sales
    GROUP BY ss_store_sk, ss_item_sk
    HAVING SUM(ss_quantity) > 100
    UNION ALL
    SELECT ss_store_sk, ss_item_sk, total_quantity + 1, total_sales + (SELECT AVG(ss_net_paid) FROM store_sales)
    FROM sales_cte
    WHERE total_quantity < 500
),
top_stores AS (
    SELECT s_store_sk, s_store_name, SUM(sr_return_quantity) AS total_returns
    FROM store_returns sr
    JOIN store s ON sr.s_store_sk = s.s_store_sk
    GROUP BY s_store_sk, s_store_name
    ORDER BY total_returns DESC
    LIMIT 10
),
customer_sales AS (
    SELECT c.c_customer_id, SUM(ws.net_paid) AS total_spent
    FROM customer c
    JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE c.c_birth_year BETWEEN 1980 AND 1995
    GROUP BY c.c_customer_id
),
item_ranking AS (
    SELECT i.i_item_id, RANK() OVER (PARTITION BY i.i_category ORDER BY SUM(ws.ws_sales_price) DESC) AS rank
    FROM web_sales ws
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    GROUP BY i.i_item_id, i.i_category
    HAVING SUM(ws.ws_sales_price) > 1000
)
SELECT ca.ca_city, ca.ca_state, 
       SUM(cs.total_spent) AS total_spending_by_customers,
       COUNT(DISTINCT ts.s_store_sk) AS number_of_stores,
       (SELECT AVG(inv_quantity_on_hand) FROM inventory inv WHERE inv.inv_item_sk IN (SELECT i_item_sk FROM item_ranking WHERE rank <= 5)) AS avg_inventory
FROM customer_address ca
LEFT JOIN customer_sales cs ON ca.ca_address_sk = cs.c_customer_sk
LEFT JOIN top_stores ts ON ts.total_returns > 10
JOIN sales_cte sc ON sc.ss_store_sk = ts.s_store_sk
WHERE ca.ca_state IN ('CA', 'NY') AND cs.total_spent IS NOT NULL
GROUP BY ca.ca_city, ca.ca_state
HAVING SUM(cs.total_spent) > 5000
ORDER BY total_spending_by_customers DESC;
