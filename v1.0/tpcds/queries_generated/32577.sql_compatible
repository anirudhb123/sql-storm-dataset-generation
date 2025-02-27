
WITH RECURSIVE SalesTotals AS (
    SELECT ss_sold_date_sk, 
           ss_item_sk, 
           SUM(ss_net_paid) AS total_sales, 
           SUM(ss_quantity) AS total_quantity
    FROM store_sales
    GROUP BY ss_sold_date_sk, ss_item_sk
    UNION ALL
    SELECT st.ss_sold_date_sk, 
           st.ss_item_sk, 
           st.total_sales + COALESCE(nst.ss_net_paid, 0), 
           st.total_quantity + COALESCE(nst.ss_quantity, 0)
    FROM SalesTotals st
    LEFT JOIN store_sales nst ON st.ss_item_sk = nst.ss_item_sk 
                             AND nst.ss_sold_date_sk > st.ss_sold_date_sk
)
SELECT 
    ca.ca_city, 
    COUNT(DISTINCT c.c_customer_sk) AS customer_count, 
    AVG(cd.cd_purchase_estimate) AS avg_purchase_estimate,
    AVG(si.total_sales) AS avg_sales_per_item,
    SUM(CASE WHEN cd.cd_marital_status = 'M' THEN 1 ELSE 0 END) AS married_count,
    STRING_AGG(DISTINCT i.i_category, ', ') AS popular_categories
FROM customer c
JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
LEFT JOIN (
    SELECT ss_item_sk, 
           SUM(ss_net_paid) AS total_sales 
    FROM store_sales 
    WHERE ss_sold_date_sk >= (SELECT MIN(d_date_sk) FROM date_dim)
    GROUP BY ss_item_sk
) AS si ON ca.ca_state = 'CA' AND si.total_sales IS NOT NULL
JOIN item i ON si.ss_item_sk = i.i_item_sk
WHERE c.c_birth_year BETWEEN 1980 AND 2000
AND cd.cd_credit_rating IS NOT NULL
AND EXISTS (
    SELECT 1 
    FROM store s 
    WHERE s.s_state = ca.ca_state AND s.s_closed_date_sk IS NULL 
    GROUP BY s.s_state
    HAVING COUNT(s.s_store_sk) > 3
)
GROUP BY ca.ca_city
ORDER BY customer_count DESC
LIMIT 10;
