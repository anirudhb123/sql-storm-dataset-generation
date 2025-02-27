
WITH RECURSIVE sales_cte AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_sold_date_sk DESC) AS rnk
    FROM web_sales
    GROUP BY ws_sold_date_sk, ws_item_sk
),
customer_orders AS (
    SELECT 
        c.c_customer_sk,
        COUNT(DISTINCT ws_order_number) AS order_count,
        SUM(ws_ext_sales_price) AS total_sales,
        MAX(ws_sold_date_sk) AS last_order_date
    FROM customer c
    JOIN web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    GROUP BY c.c_customer_sk
),
top_customers AS (
    SELECT 
        co.c_customer_sk,
        co.order_count,
        co.total_sales,
        COALESCE((SELECT cd_gender FROM customer_demographics cd 
                  WHERE cd.cd_demo_sk = c.c_current_cdemo_sk), 'N/A') AS gender,
        RANK() OVER (ORDER BY co.total_sales DESC) AS sales_rank
    FROM customer_orders co
    JOIN customer c ON co.c_customer_sk = c.c_customer_sk
    WHERE co.total_sales IS NOT NULL
),
sales_summary AS (
    SELECT 
        s.ws_item_sk,
        s.total_quantity,
        i.i_current_price,
        i.i_item_desc,
        ((s.total_quantity * i.i_current_price) - COALESCE(NULLIF(ws_ext_discount_amt, 0), 0)) AS net_sales
    FROM sales_cte s
    JOIN item i ON s.ws_item_sk = i.i_item_sk
    WHERE s.rnk = 1
)
SELECT 
    tc.c_customer_sk,
    tc.gender,
    tc.order_count,
    tc.total_sales,
    ss.ws_item_sk,
    ss.net_sales,
    DENSE_RANK() OVER (PARTITION BY tc.c_customer_sk ORDER BY ss.net_sales DESC) AS item_rank
FROM top_customers tc
LEFT JOIN sales_summary ss ON tc.c_customer_sk = ss.ws_item_sk
WHERE tc.sales_rank <= 10
  AND ss.net_sales IS NOT NULL
ORDER BY tc.c_customer_sk, item_rank;
