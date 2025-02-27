
WITH RECURSIVE CustomerHierarchy AS (
    SELECT c.c_customer_sk,
           c.c_first_name,
           c.c_last_name,
           c.c_current_cdemo_sk,
           1 AS level
    FROM customer c
    WHERE c.c_current_cdemo_sk IS NOT NULL
    UNION ALL
    SELECT ch.c_customer_sk,
           c.c_first_name,
           c.c_last_name,
           c.c_current_cdemo_sk,
           ch.level + 1
    FROM CustomerHierarchy ch
    JOIN customer c ON ch.c_current_cdemo_sk = c.c_current_cdemo_sk
    WHERE ch.level < 3 -- arbitrary depth limit
),
RankedSales AS (
    SELECT ws.ws_item_sk,
           SUM(ws.ws_quantity) AS total_sold,
           RANK() OVER (PARTITION BY ws.ws_bill_customer_sk ORDER BY SUM(ws.ws_quantity) DESC) AS item_rank
    FROM web_sales ws
    JOIN CustomerHierarchy ch ON ws.ws_bill_customer_sk = ch.c_customer_sk
    GROUP BY ws.ws_item_sk
),
HighValueReturns AS (
    SELECT sr_item_sk,
           SUM(sr_return_quantity) AS total_returns,
           AVG(sr_return_amt_inc_tax) AS avg_return_value
    FROM store_returns
    WHERE sr_returned_date_sk IN (SELECT DISTINCT d_date_sk 
                                    FROM date_dim 
                                    WHERE d_year = 2023)
    GROUP BY sr_item_sk
    HAVING SUM(sr_return_quantity) > 50 OR avg_return_value IS NOT NULL
)
SELECT COALESCE(ch.c_first_name || ' ' || ch.c_last_name, 'Unknown Customer') AS customer_name,
       r.total_sold,
       r.item_rank,
       COALESCE(h.total_returns, 0) AS total_returns,
       COALESCE(h.avg_return_value, 0.00) AS avg_return_value,
       CASE 
           WHEN ch.level IS NULL THEN 'No Hierarchy'
           WHEN ch.level = 1 THEN 'First Level'
           ELSE 'Subsequent Level'
       END AS hierarchy_level
FROM CustomerHierarchy ch
LEFT JOIN RankedSales r ON ch.c_customer_sk = r.ws_bill_customer_sk
LEFT JOIN HighValueReturns h ON r.ws_item_sk = h.sr_item_sk
WHERE (r.item_rank <= 10 OR r.item_rank IS NULL)
  AND (h.total_returns IS NULL OR h.avg_return_value IS NOT NULL)
ORDER BY customer_name, r.total_sold DESC;
