
WITH RECURSIVE SalesHierarchy AS (
    SELECT ws_item_sk, SUM(ws_quantity) AS total_quantity, 
           ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_quantity) DESC) AS sales_rank
    FROM web_sales
    WHERE ws_sold_date_sk BETWEEN 2452110 AND 2452150
    GROUP BY ws_item_sk
),
CustomerFeedback AS (
    SELECT c.c_customer_id, 
           COUNT(DISTINCT wp.wp_web_page_sk) AS feedback_count,
           AVG(ws_ext_sales_price) AS avg_sales_price
    FROM customer c
    LEFT JOIN web_page wp ON c.c_customer_sk = wp.wp_customer_sk
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE c.c_birth_year < 1990
    GROUP BY c.c_customer_id
),
TotalReturns AS (
    SELECT sr_item_sk, 
           SUM(sr_return_quantity) AS total_returned, 
           COUNT(DISTINCT sr_ticket_number) AS total_tickets
    FROM store_returns
    WHERE sr_returned_date_sk > 2452140
    GROUP BY sr_item_sk
),
FilteredReturns AS (
    SELECT r.r_reason_desc, 
           tr.total_returned,
           tr.total_tickets
    FROM TotalReturns tr
    JOIN reason r ON tr.sr_item_sk = r.r_reason_sk
)
SELECT sh.ws_item_sk, 
       sh.total_quantity, 
       cf.feedback_count, 
       cf.avg_sales_price,
       fr.total_returned,
       fr.total_tickets,
       CASE 
           WHEN fr.total_returned IS NULL THEN 'No Returns'
           ELSE 'Returns Present'
       END AS return_status
FROM SalesHierarchy sh
JOIN CustomerFeedback cf ON sh.ws_item_sk = cf.c_customer_id
FULL OUTER JOIN FilteredReturns fr ON sh.ws_item_sk = fr.sr_item_sk
WHERE (cf.avg_sales_price > 20 OR sh.total_quantity > 100)
  AND (fr.total_returned IS NULL OR fr.total_returned < 10)
ORDER BY sh.total_quantity DESC, cf.feedback_count DESC;
