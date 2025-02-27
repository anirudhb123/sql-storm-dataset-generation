
WITH RECURSIVE sales_cte AS (
    SELECT ws_item_sk, 
           SUM(ws_quantity) AS total_sales, 
           ws_sold_date_sk
    FROM web_sales 
    GROUP BY ws_item_sk, ws_sold_date_sk
    UNION ALL
    SELECT ws_item_sk, 
           total_sales + ws_quantity, 
           ws_sold_date_sk
    FROM sales_cte
    JOIN web_sales ON sales_cte.ws_item_sk = web_sales.ws_item_sk 
    WHERE web_sales.ws_sold_date_sk > sales_cte.ws_sold_date_sk
), item_performance AS (
    SELECT i.i_item_sk,
           i.i_item_desc,
           COALESCE(wp.wp_web_page_id, 'N/A') AS web_page_id,
           SUM(ws_ext_sales_price) AS total_revenue,
           RANK() OVER (PARTITION BY i.i_item_sk ORDER BY SUM(ws_ext_sales_price) DESC) AS sales_rank
    FROM item i
    LEFT JOIN web_sales ws ON i.i_item_sk = ws.ws_item_sk
    LEFT JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    GROUP BY i.i_item_sk, i.i_item_desc, wp.wp_web_page_id
), high_performers AS (
    SELECT ip.i_item_sk,
           ip.i_item_desc,
           ip.total_revenue
    FROM item_performance ip
    WHERE ip.sales_rank <= 10
)
SELECT h.i_item_sk,
       h.i_item_desc,
       h.total_revenue,
       COALESCE(c.c_first_name || ' ' || c.c_last_name, 'Unknown Customer') AS customer_name,
       CASE 
           WHEN h.total_revenue IS NULL THEN 'No sales' 
           ELSE 'Sales recorded' 
       END AS sales_status,
       (SELECT COUNT(*) 
        FROM store_sales ss 
        WHERE ss.ss_item_sk = h.i_item_sk) AS store_sales_count
FROM high_performers h
LEFT JOIN customer c ON c.c_customer_sk = 
    (SELECT ws_bill_customer_sk 
     FROM web_sales 
     WHERE ws_item_sk = h.i_item_sk 
     ORDER BY ws_sold_date_sk DESC 
     LIMIT 1)
ORDER BY h.total_revenue DESC;
