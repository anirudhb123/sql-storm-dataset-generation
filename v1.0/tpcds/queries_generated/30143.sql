
WITH RECURSIVE sales_hierarchy AS (
    SELECT ws.bill_customer_sk, 
           SUM(ws.net_profit) AS total_profit,
           ROW_NUMBER() OVER (PARTITION BY ws.bill_customer_sk ORDER BY SUM(ws.net_profit) DESC) AS rank
    FROM web_sales ws
    JOIN customer c ON ws.bill_customer_sk = c.c_customer_sk
    WHERE c.c_birth_month = 12
    GROUP BY ws.bill_customer_sk
),
top_customers AS (
    SELECT sh.bill_customer_sk, sh.total_profit
    FROM sales_hierarchy sh
    WHERE sh.rank <= 10
),
detailed_sales AS (
    SELECT ws.ws_item_sk, 
           SUM(ws.ws_quantity) AS total_quantity,
           SUM(ws.ws_ext_sales_price) AS total_sales,
           AVG(ws.ws_net_paid) AS avg_net_paid
    FROM web_sales ws
    JOIN top_customers tc ON ws.bill_customer_sk = tc.bill_customer_sk
    GROUP BY ws.ws_item_sk
),
sales_analysis AS (
    SELECT ds.ws_item_sk,
           ds.total_quantity,
           ds.total_sales,
           ds.avg_net_paid,
           i.i_item_desc,
           i.i_current_price,
           COALESCE(r.r_reason_desc, 'No Reason') AS return_reason
    FROM detailed_sales ds
    LEFT JOIN item i ON ds.ws_item_sk = i.i_item_sk
    LEFT JOIN web_returns wr ON ds.ws_item_sk = wr.wr_item_sk
    LEFT JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
)
SELECT sa.ws_item_sk,
       sa.total_quantity,
       sa.total_sales,
       sa.avg_net_paid,
       sa.i_item_desc,
       sa.i_current_price,
       CASE 
           WHEN sa.total_quantity > 50 THEN 'High Volume'
           WHEN sa.total_quantity BETWEEN 20 AND 50 THEN 'Medium Volume'
           ELSE 'Low Volume'
       END AS volume_category
FROM sales_analysis sa
WHERE sa.total_sales > (SELECT AVG(total_sales) FROM detailed_sales)
ORDER BY sa.total_quantity DESC
LIMIT 15;
