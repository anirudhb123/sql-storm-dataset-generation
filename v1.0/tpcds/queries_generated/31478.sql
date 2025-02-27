
WITH RECURSIVE sales_cte AS (
    SELECT ws_date_sk, ws_item_sk, SUM(ws_ext_sales_price) AS total_sales, 
           ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_ext_sales_price) DESC) AS rn
    FROM web_sales
    GROUP BY ws_date_sk, ws_item_sk
),
returns_cte AS (
    SELECT sr_item_sk, SUM(sr_return_amt) AS total_returns
    FROM store_returns
    GROUP BY sr_item_sk
),
item_summary AS (
    SELECT i.i_item_id, i.i_item_desc, COALESCE(s.total_sales, 0) AS total_sales, COALESCE(r.total_returns, 0) AS total_returns,
           (COALESCE(s.total_sales, 0) - COALESCE(r.total_returns, 0)) AS net_sales
    FROM item i
    LEFT JOIN (SELECT ws_item_sk, SUM(ws_ext_sales_price) AS total_sales
                FROM web_sales
                WHERE ws_sold_date_sk BETWEEN 2451545 AND 2451549
                GROUP BY ws_item_sk) s ON i.i_item_sk = s.ws_item_sk
    LEFT JOIN returns_cte r ON i.i_item_sk = r.sr_item_sk
),
district_sales AS (
    SELECT s.s_store_id, SUM(ss_ext_sales_price) AS store_total_sales
    FROM store_sales s
    WHERE s.ss_sold_date_sk BETWEEN 2451545 AND 2451549
    GROUP BY s.s_store_id
),
top_stores AS (
    SELECT d.s_store_id, d.store_total_sales, 
           RANK() OVER (ORDER BY d.store_total_sales DESC) AS sales_rank
    FROM district_sales d
)
SELECT ts.s_store_id, ts.store_total_sales, ISNULL(i.net_sales, 0) AS item_net_sales, 
       i.i_item_desc, i.i_item_id
FROM top_stores ts
FULL OUTER JOIN item_summary i ON ts.store_total_sales > 0 AND i.total_sales > 0
WHERE ts.sales_rank <= 10
ORDER BY ts.store_total_sales DESC, i.item_net_sales DESC
LIMIT 100;
