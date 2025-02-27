
WITH RECURSIVE customer_hierarchy AS (
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, c.c_current_addr_sk, 1 AS level
    FROM customer c
    WHERE c.c_preferred_cust_flag = 'Y'
    UNION ALL
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, c.c_current_addr_sk, ch.level + 1
    FROM customer c
    JOIN customer_hierarchy ch ON ch.c_customer_sk = c.c_current_hdemo_sk
),
address_info AS (
    SELECT ca.ca_address_sk, ca.ca_city, ca.ca_state, 
           COALESCE(ca.ca_zip, 'ZIP UNKNOWN') AS final_zip,
           ROW_NUMBER() OVER(PARTITION BY ca.ca_city ORDER BY ca.ca_address_sk) AS city_rank
    FROM customer_address ca
),
filtered_sales AS (
    SELECT ws.ws_item_sk, SUM(ws.ws_quantity) AS total_sales,
           (SUM(ws.ws_net_paid_inc_tax) / NULLIF(SUM(ws.ws_quantity), 0)) AS avg_price,
           CURRENT_TIMESTAMP AS sales_time
    FROM web_sales ws
    WHERE ws.ws_sold_date_sk = (SELECT MAX(d.d_date_sk) 
                                 FROM date_dim d 
                                 WHERE d.d_date = CURRENT_DATE)
    GROUP BY ws.ws_item_sk
)
SELECT ch.c_first_name, ch.c_last_name, ad.ca_city, ad.final_zip, 
       fs.total_sales, fs.avg_price,
       MAX(CASE WHEN fs.avg_price > 100 THEN 'High' ELSE 'Low' END) AS price_category,
       ARRAY(SELECT DISTINCT i.i_brand 
             FROM item i 
             WHERE i.i_item_sk = fs.ws_item_sk AND i.i_rec_end_date IS NULL) AS brands_available
FROM customer_hierarchy ch
LEFT JOIN address_info ad ON ch.c_current_addr_sk = ad.ca_address_sk
LEFT JOIN filtered_sales fs ON fs.ws_item_sk IN (SELECT DISTINCT sr_item_sk 
                                                  FROM store_returns 
                                                  WHERE sr_return_quantity > 0)
WHERE ad.city_rank = 1
  AND (ch.level % 2 = 0 OR ad.final_zip IS NOT NULL)
GROUP BY ch.c_first_name, ch.c_last_name, ad.ca_city, ad.final_zip, fs.total_sales, fs.avg_price
ORDER BY fs.total_sales DESC
LIMIT 100;
