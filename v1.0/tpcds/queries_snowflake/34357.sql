
WITH RECURSIVE sales_cte (ss_sold_date_sk, ss_item_sk, total_sales) AS (
    SELECT ss_sold_date_sk, ss_item_sk, SUM(ss_net_paid) AS total_sales
    FROM store_sales
    GROUP BY ss_sold_date_sk, ss_item_sk
    UNION ALL
    SELECT s.ss_sold_date_sk, s.ss_item_sk, SUM(s.ss_net_paid)
    FROM store_sales s
    JOIN sales_cte c ON s.ss_item_sk = c.ss_item_sk AND s.ss_sold_date_sk > c.ss_sold_date_sk
    GROUP BY s.ss_sold_date_sk, s.ss_item_sk
),
customer_info AS (
    SELECT c.c_customer_sk, cd.cd_gender, cd.cd_marital_status, cd.cd_purchase_estimate,
           CA1.ca_state AS customer_state, CA1.ca_city AS customer_city
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address CA1 ON c.c_current_addr_sk = CA1.ca_address_sk
),
sales_data AS (
    SELECT si.ss_item_sk, SUM(si.ss_net_paid) AS total_net_paid, 
           COUNT(DISTINCT si.ss_customer_sk) AS unique_customers
    FROM store_sales si
    GROUP BY si.ss_item_sk
),
join_totals AS (
    SELECT c.c_customer_sk, c.cd_gender, c.cd_marital_status, 
           c.cd_purchase_estimate, s.total_net_paid, s.unique_customers
    FROM customer_info c
    LEFT JOIN sales_data s ON c.c_customer_sk = s.ss_item_sk
)
SELECT j.cd_gender, j.cd_marital_status, 
       COALESCE(AVG(j.total_net_paid), 0) AS avg_net_paid, 
       SUM(CASE WHEN j.unique_customers IS NULL THEN 1 ELSE 0 END) AS customer_without_sales,
       RANK() OVER (PARTITION BY j.cd_gender ORDER BY COALESCE(AVG(j.total_net_paid), 0) DESC) AS gender_rank
FROM join_totals j
GROUP BY j.cd_gender, j.cd_marital_status
HAVING COUNT(*) > 1
ORDER BY j.cd_gender, avg_net_paid DESC;
