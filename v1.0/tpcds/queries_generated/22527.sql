
WITH ranked_sales AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_item_sk,
        ws.ws_sales_price,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_order_number ORDER BY ws.ws_sales_price DESC) AS item_rank
    FROM web_sales ws
    WHERE ws.ws_ship_date_sk IS NOT NULL
),
customer_return_metrics AS (
    SELECT
        c.c_customer_id,
        COUNT(DISTINCT wr.wr_order_number) AS total_returns,
        SUM(wr.wr_return_amt) AS total_return_amount,
        SUM(COALESCE(wr.wr_fee, 0)) AS total_return_fee
    FROM customer c
    LEFT JOIN web_returns wr ON c.c_customer_sk = wr.wr_returning_customer_sk
    GROUP BY c.c_customer_id
),
aggregated_sales AS (
    SELECT 
        cs.cs_customer_sk,
        SUM(cs.cs_sales_price) AS total_sales,
        SUM(CASE WHEN cs.cs_sales_price < 0 THEN 1 ELSE 0 END) AS negative_sales_count,
        AVG(cs.cs_sales_price) AS average_sale
    FROM catalog_sales cs
    GROUP BY cs.cs_customer_sk
)
SELECT 
    c.c_customer_id,
    r.total_returns,
    r.total_return_amount,
    r.total_return_fee,
    a.total_sales,
    a.negative_sales_count,
    a.average_sale,
    i.i_item_desc,
    COALESCE(RANK() OVER (PARTITION BY a.cs_customer_sk ORDER BY a.total_sales DESC), 0) as sales_rank,
    (SELECT COUNT(*)
     FROM store_sales ss 
     WHERE ss.ss_item_sk = i.i_item_sk 
       AND ss.ss_sold_date_sk BETWEEN 20220101 AND 20221231
       AND ss.ss_quantity IS NOT NULL) AS store_sales_count
FROM customer_return_metrics r
JOIN aggregated_sales a ON r.c_customer_id = a.cs_customer_sk
JOIN item i ON a.cs_customer_sk = i.i_item_sk
LEFT JOIN ranked_sales rs ON rs.ws_order_number = (
    SELECT ws_order_number 
    FROM web_sales 
    WHERE ws_item_sk = i.i_item_sk 
    ORDER BY ws_sales_price DESC 
    LIMIT 1
) OR i.i_item_sk IS NULL
WHERE r.total_return_amount > (SELECT AVG(total_return_amount) FROM customer_return_metrics)
  AND (r.total_returns IS NULL OR r.total_returns > 0)
  AND a.average_sale BETWEEN 10.00 AND 500.00
ORDER BY r.total_return_amount DESC, a.total_sales DESC
LIMIT 100;
