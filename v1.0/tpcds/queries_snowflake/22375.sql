
WITH RECURSIVE sales_cte AS (
    SELECT ss_item_sk, 
           SUM(ss_quantity) AS total_quantity,
           SUM(ss_ext_sales_price) AS total_sales
    FROM store_sales
    WHERE ss_sold_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2022) AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY ss_item_sk
),
address_details AS (
    SELECT c.c_customer_sk, 
           ca.ca_city, 
           ca.ca_state,
           CASE 
               WHEN ca.ca_country IS NULL THEN 'Unknown' 
               ELSE ca.ca_country 
           END AS adjusted_country
    FROM customer c
    LEFT JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
promotional_data AS (
    SELECT p.p_promo_sk, 
           p.p_promo_name, 
           SUM(ws.ws_ext_discount_amt) AS total_discount
    FROM web_sales ws
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    WHERE p.p_start_date_sk <= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
      AND p.p_end_date_sk >= (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2022)
    GROUP BY p.p_promo_sk, p.p_promo_name
)
SELECT ad.adjusted_country,
       COALESCE(SUM(s.total_sales), 0) AS total_sales,
       COALESCE(pd.total_discount, 0) AS total_discount,
       COUNT(DISTINCT ad.c_customer_sk) AS unique_customers,
       PERCENT_RANK() OVER (ORDER BY COALESCE(SUM(s.total_sales), 0) DESC) AS sales_rank
FROM sales_cte s
FULL OUTER JOIN address_details ad ON s.ss_item_sk = ad.c_customer_sk
LEFT JOIN promotional_data pd ON pd.p_promo_sk = (SELECT p.p_promo_sk FROM promotion p ORDER BY RANDOM() LIMIT 1)
GROUP BY ad.adjusted_country, pd.total_discount
HAVING COUNT(DISTINCT ad.c_customer_sk) > 10
ORDER BY sales_rank;
