
WITH RECURSIVE itemHierarchy AS (
    SELECT i_item_sk, i_item_id, i_item_desc, i_current_price, i_brand
    FROM item
    WHERE i_current_price > (SELECT AVG(i_current_price) FROM item) -- Base case: items with above-average price

    UNION ALL

    SELECT i.i_item_sk, i.i_item_id, i.i_item_desc, i.i_current_price, i.i_brand
    FROM item i
    JOIN itemHierarchy ih ON i.i_item_sk = ih.i_item_sk
    WHERE i.i_current_price < ih.i_current_price -- Recursive case: items with lower price than their parent
),
sales_data AS (
    SELECT ws.ws_item_sk, SUM(ws.ws_quantity) AS total_quantity, SUM(ws.ws_ext_sales_price) AS total_sales
    FROM web_sales ws
    WHERE ws.ws_sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2023)
    GROUP BY ws.ws_item_sk
),
customer_returns AS (
    SELECT sr_customer_sk, COUNT(*) AS total_returns
    FROM store_returns
    WHERE sr_return_quantity > 0
    GROUP BY sr_customer_sk
),
final_summary AS (
    SELECT ih.i_item_id, ih.i_item_desc, sd.total_quantity, sd.total_sales, 
           COALESCE(cr.total_returns, 0) AS total_returns,
           CASE 
               WHEN sd.total_sales > 1000 THEN 'High Value' 
               ELSE 'Low Value' 
           END AS sales_category
    FROM itemHierarchy ih
    LEFT JOIN sales_data sd ON ih.i_item_sk = sd.ws_item_sk
    LEFT JOIN customer_returns cr ON cr.sr_customer_sk = (SELECT c_customer_sk FROM customer WHERE c_current_addr_sk = sd.ws_item_sk)
)
SELECT f.i_item_id, f.i_item_desc, f.total_quantity, f.total_sales, f.total_returns, f.sales_category
FROM final_summary f
WHERE f.total_sales IS NOT NULL 
  AND (f.sales_category = 'High Value' OR f.total_returns > 0)
ORDER BY f.total_sales DESC, f.total_returns DESC
LIMIT 50;
