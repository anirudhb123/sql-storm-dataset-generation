
WITH RECURSIVE ItemHierarchy AS (
    SELECT i_item_sk, i_item_id, i_item_desc, i_current_price, 
           1 AS level, CAST(i_item_id AS VARCHAR(255)) AS path
    FROM item
    WHERE i_item_sk IN (SELECT sr_item_sk FROM store_returns WHERE sr_returned_date_sk > 20230101)
    UNION ALL
    SELECT i.i_item_sk, i.i_item_id, i.i_item_desc, i.i_current_price, 
           h.level + 1, CONCAT(h.path, ' > ', i.i_item_id)
    FROM item i
    JOIN ItemHierarchy h ON i.i_item_sk = (SELECT sr_item_sk FROM store_returns WHERE sr_ticket_number = h.i_item_sk LIMIT 1)
)
SELECT 
    i.item_id,
    i.item_desc,
    i.current_price,
    COALESCE(SUM(ws.net_profit), 0) AS total_net_profit,
    COUNT(DISTINCT sr.ticket_number) AS return_count,
    ROW_NUMBER() OVER (PARTITION BY i.item_id ORDER BY COALESCE(SUM(ws.net_profit), 0) DESC) AS rank
FROM item i
LEFT JOIN web_sales ws ON i.i_item_sk = ws.ws_item_sk AND ws.ws_sold_date_sk = (
        SELECT MAX(ws_sold_date_sk) 
        FROM web_sales 
        WHERE ws_item_sk = i.i_item_sk
        )
LEFT JOIN store_returns sr ON i.i_item_sk = sr.sr_item_sk 
WHERE i.i_current_price > (
    SELECT AVG(i_current_price) 
    FROM item
    WHERE i_rec_end_date IS NULL
) AND 
EXISTS (
    SELECT 1 
    FROM customer c 
    WHERE c.c_customer_sk IN (
        SELECT ws_bill_customer_sk 
        FROM web_sales 
        WHERE ws_item_sk = i.i_item_sk
    ) 
    AND c.c_birth_year < (2023 - 30)
)
GROUP BY i.item_id, i.item_desc, i.current_price
HAVING total_net_profit > 1000
ORDER BY rank, return_count DESC
LIMIT 10;
