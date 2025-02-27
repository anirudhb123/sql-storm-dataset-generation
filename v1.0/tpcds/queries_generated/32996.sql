
WITH RECURSIVE customer_hierarchy AS (
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, c.c_current_cdemo_sk,
           1 AS level
    FROM customer c
    WHERE c.c_current_cdemo_sk IS NOT NULL
    UNION ALL
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, c.c_current_cdemo_sk,
           ch.level + 1
    FROM customer c
    JOIN customer_hierarchy ch ON c.c_current_cdemo_sk = ch.c_current_cdemo_sk
),
item_sales AS (
    SELECT ws.ws_item_sk, ws.ws_order_number, SUM(ws.ws_quantity) AS total_quantity,
           SUM(ws.ws_net_sales_price) AS total_sales
    FROM web_sales ws
    GROUP BY ws.ws_item_sk, ws.ws_order_number
),
item_average_sales AS (
    SELECT i.i_item_sk, AVG(is.total_sales) AS average_sales
    FROM item i
    JOIN item_sales is ON i.i_item_sk = is.ws_item_sk
    GROUP BY i.i_item_sk
),
recent_returns AS (
    SELECT sr.sr_item_sk, COUNT(sr.sr_ticket_number) AS return_count,
           SUM(sr.sr_return_amt_inc_tax) AS total_returned
    FROM store_returns sr
    WHERE sr.sr_returned_date_sk >= (SELECT MAX(d.d_date_sk) 
                                       FROM date_dim d 
                                       WHERE d.d_date = CURRENT_DATE - INTERVAL '30 days')
    GROUP BY sr.sr_item_sk
)
SELECT cu.c_first_name, cu.c_last_name, 
       COALESCE(ia.average_sales, 0) AS avg_sales,
       COALESCE(rr.return_count, 0) AS return_count,
       COALESCE(rr.total_returned, 0) AS total_returned,
       RANK() OVER (ORDER BY COALESCE(ia.average_sales, 0) DESC) AS sales_rank
FROM customer_hierarchy cu
LEFT JOIN item_average_sales ia ON ia.i_item_sk = cu.c_current_cdemo_sk
LEFT JOIN recent_returns rr ON rr.sr_item_sk = ia.i_item_sk
WHERE COALESCE(rr.return_count, 0) < 5
  AND cu.level = 1
ORDER BY sales_rank
LIMIT 100;
