
WITH RECURSIVE item_hierarchy AS (
    SELECT i_item_sk, i_item_desc, i_category, i_brand
    FROM item
    WHERE i_item_sk IS NOT NULL
    UNION ALL
    SELECT i.i_item_sk, i.i_item_desc, i.category_id, i.brand
    FROM item i
    INNER JOIN item_hierarchy ih ON i.i_item_sk = ih.i_item_sk
),
customer_sales AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        COUNT(DISTINCT ws.ws_web_page_sk) AS unique_web_pages,
        DENSE_RANK() OVER (PARTITION BY c.c_customer_id ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS sales_rank
    FROM customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY c.c_customer_id
),
sales_summary AS (
    SELECT 
        cs.c_customer_id,
        cs.total_sales,
        CASE 
            WHEN cs.total_sales IS NULL THEN 'No Sales'
            WHEN cs.total_sales < 1000 THEN 'Low Sales'
            WHEN cs.total_sales BETWEEN 1000 AND 5000 THEN 'Medium Sales'
            ELSE 'High Sales' 
        END AS sales_bracket
    FROM customer_sales cs
)
SELECT 
    ss.c_customer_id,
    ss.total_sales,
    ss.sales_bracket,
    ih.i_item_desc,
    ih.i_brand,
    sm.sm_type,
    COUNT(DISTINCT wr.w_return_number) AS total_returns
FROM sales_summary ss
JOIN item_hierarchy ih ON ih.i_item_sk = ss.c_customer_id
LEFT JOIN web_returns wr ON wr.wr_returning_customer_sk = ss.c_customer_id
LEFT JOIN ship_mode sm ON sm.sm_ship_mode_sk = (SELECT TOP 1 ws.ws_ship_mode_sk FROM web_sales ws WHERE ws.ws_bill_customer_sk = ss.c_customer_id)
WHERE ss.total_sales > 1000
GROUP BY ss.c_customer_id, ss.total_sales, ss.sales_bracket, ih.i_item_desc, ih.i_brand, sm.sm_type
HAVING COUNT(DISTINCT wr.w_return_number) > 0
ORDER BY ss.total_sales DESC
LIMIT 10;
