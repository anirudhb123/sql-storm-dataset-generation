
WITH RECURSIVE CategoryHierarchy AS (
    SELECT i_item_sk, i_item_desc, i_brand, i_category, 1 AS level
    FROM item
    WHERE i_rec_start_date <= CURRENT_DATE AND (i_rec_end_date IS NULL OR i_rec_end_date >= CURRENT_DATE)

    UNION ALL

    SELECT ch.i_item_sk, ch.i_item_desc, ch.i_brand, ch.i_category, ch.level + 1
    FROM item ch
    JOIN CategoryHierarchy c ON ch.i_brand = c.i_brand
    WHERE ch.i_rec_start_date <= CURRENT_DATE AND (ch.i_rec_end_date IS NULL OR ch.i_rec_end_date >= CURRENT_DATE)
)

SELECT c.c_customer_id,
       SUM(ws.ws_ext_sales_price) AS total_sales,
       COUNT(DISTINCT ws.ws_order_number) AS order_count,
       AVG(ws.ws_sales_price) AS avg_sales_price,
       MIN(ws.ws_list_price) AS min_price,
       MAX(ws.ws_list_price) AS max_price,
       COALESCE(cd.cd_gender, 'Unknown') AS gender,
       COALESCE(hd.hd_buy_potential, 'Low') AS potential_buy,
       ch.i_category, 
       DENSE_RANK() OVER (PARTITION BY ch.i_category ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS sales_rank
FROM web_sales ws
LEFT JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
LEFT JOIN household_demographics hd ON cd.cd_demo_sk = hd.hd_demo_sk
JOIN CategoryHierarchy ch ON ws.ws_item_sk = ch.i_item_sk
WHERE ws.ws_sold_date_sk BETWEEN (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = EXTRACT(YEAR FROM CURRENT_DATE) - 1) AND 
                                    (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = EXTRACT(YEAR FROM CURRENT_DATE))
GROUP BY c.c_customer_id, cd.cd_gender, hd.hd_buy_potential, ch.i_category
HAVING COUNT(DISTINCT ws.ws_order_number) > 5
ORDER BY total_sales DESC
LIMIT 10;
