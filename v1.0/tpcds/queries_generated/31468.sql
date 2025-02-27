
WITH RECURSIVE customer_hierarchy AS (
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, c.c_current_cdemo_sk, 1 AS level
    FROM customer c
    WHERE c.c_customer_sk IS NOT NULL

    UNION ALL

    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, c.c_current_cdemo_sk, ch.level + 1
    FROM customer_hierarchy ch
    JOIN customer c ON ch.c_current_cdemo_sk = c.c_current_cdemo_sk
    WHERE ch.level < 5
),
sales_data AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_paid) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_net_paid) DESC) AS rn
    FROM web_sales
    GROUP BY ws_sold_date_sk, ws_item_sk
),
best_selling_items AS (
    SELECT ws_item_sk, total_quantity, total_sales
    FROM sales_data
    WHERE rn <= 10
),
customer_sales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS order_count,
        COUNT(DISTINCT ws_item_sk) AS unique_items_purchased
    FROM customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name
),
top_customers AS (
    SELECT 
        cs.c_customer_sk,
        cs.c_first_name,
        cs.c_last_name,
        cs.total_sales,
        cs.order_count,
        cs.unique_items_purchased,
        ROW_NUMBER() OVER (ORDER BY cs.total_sales DESC) AS rank
    FROM customer_sales cs
    WHERE cs.total_sales > 0
)
SELECT 
    cu.c_first_name || ' ' || cu.c_last_name AS customer_name, 
    cu.total_sales, 
    cu.order_count,
    COALESCE(NULLIF(ROUND((cu.total_sales / NULLIF(s.total_sales, 0)) * 100, 2), 0), 'N/A') AS sales_percentage,
    ch.level AS hierarchy_level
FROM top_customers cu
LEFT JOIN (SELECT SUM(total_sales) AS total_sales FROM top_customers) s ON 1=1
JOIN customer_hierarchy ch ON cu.c_customer_sk = ch.c_customer_sk
WHERE cu.rank <= 50
ORDER BY cu.total_sales DESC, customer_name
FETCH FIRST 20 ROWS ONLY;
