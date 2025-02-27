
WITH RECURSIVE sales_hierarchy AS (
    SELECT ss_store_sk, ss_item_sk, SUM(ss_quantity) AS total_quantity
    FROM store_sales
    WHERE ss_sold_date_sk BETWEEN (SELECT d_date_sk FROM date_dim WHERE d_date = '2023-01-01')
    AND (SELECT d_date_sk FROM date_dim WHERE d_date = '2023-12-31')
    GROUP BY ss_store_sk, ss_item_sk
    
    UNION ALL
    
    SELECT sh.ss_store_sk, sh.ss_item_sk, sh.total_quantity + s.ss_quantity
    FROM sales_hierarchy sh
    JOIN store_sales s ON sh.ss_store_sk = s.ss_store_sk 
        AND sh.ss_item_sk = s.ss_item_sk
    WHERE s.ss_sold_date_sk < (SELECT MAX(ss_sold_date_sk) FROM store_sales)
),
aggregate_sales AS (
    SELECT ss_store_sk, ss_item_sk, SUM(total_quantity) AS cumulative_quantity
    FROM sales_hierarchy
    GROUP BY ss_store_sk, ss_item_sk
),
item_details AS (
    SELECT i.i_item_sk, i.i_item_desc, i.i_current_price, ad.ca_city
    FROM item i
    JOIN customer_address ad ON i.i_item_sk = ad.ca_address_sk 
    WHERE ad.ca_country = 'USA'
),
final_report AS (
    SELECT
        id.i_item_sk,
        id.i_item_desc,
        id.i_current_price,
        asales.cumulative_quantity,
        row_number() OVER (PARTITION BY id.ca_city ORDER BY asales.cumulative_quantity DESC) as rank
    FROM aggregate_sales asales
    JOIN item_details id ON asales.ss_item_sk = id.i_item_sk
)
SELECT 
    fr.i_item_sk, 
    fr.i_item_desc, 
    fr.i_current_price, 
    fr.cumulative_quantity,
    fr.rank
FROM final_report fr
WHERE fr.rank <= 10 OR fr.rank IS NULL
ORDER BY fr.cumulative_quantity DESC;
