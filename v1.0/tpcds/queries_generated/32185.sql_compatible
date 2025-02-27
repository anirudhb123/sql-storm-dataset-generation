
WITH RECURSIVE CategoryHierarchy AS (
    SELECT i_item_sk, i_item_desc, i_brand, 
           COALESCE(SUM(ws_ext_sales_price), 0) AS total_sales,
           1 AS level
    FROM item
    LEFT JOIN web_sales ON item.i_item_sk = web_sales.ws_item_sk
    GROUP BY i_item_sk, i_item_desc, i_brand

    UNION ALL

    SELECT ch.i_item_sk, ch.i_item_desc, ch.i_brand, 
           COALESCE(ch.total_sales + SUM(ws_ext_sales_price), 0) AS total_sales,
           ch.level + 1
    FROM CategoryHierarchy ch
    LEFT JOIN item i ON i.i_item_sk = ch.i_item_sk
    LEFT JOIN web_sales ws ON i.i_item_sk = ws.ws_item_sk 
    WHERE ch.level < 5
    GROUP BY ch.i_item_sk, ch.i_item_desc, ch.i_brand, ch.total_sales, ch.level
)

SELECT c.c_customer_id,
       ca.ca_city,
       SUM(ws.ws_sales_price) AS total_spent,
       COUNT(CASE WHEN wr.wr_item_sk IS NOT NULL THEN 1 END) AS total_returns,
       ROW_NUMBER() OVER (PARTITION BY ca.ca_city ORDER BY SUM(ws.ws_sales_price) DESC) AS rank_by_spending
FROM customer c
JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
LEFT JOIN web_returns wr ON wr.wr_returning_customer_sk = c.c_customer_sk
JOIN CategoryHierarchy ch ON ch.i_item_sk = ws.ws_item_sk
WHERE ws.ws_sold_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023) 
      AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
      AND (c.c_birth_year IS NULL OR c.c_birth_year >= 1980)
      AND (ca.ca_state IN ('CA', 'TX') OR ca.ca_city LIKE '%San%')
GROUP BY c.c_customer_id, ca.ca_city
HAVING SUM(ws.ws_sales_price) > 1000
ORDER BY total_spent DESC;
