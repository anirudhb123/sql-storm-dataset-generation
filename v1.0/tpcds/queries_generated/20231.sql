
WITH RECURSIVE customer_hierarchy AS (
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, 
           cd.cd_demo_sk, cd.cd_gender, cd.cd_marital_status,
           cd.cd_purchase_estimate,
           ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS rn
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE cd.cd_purchase_estimate IS NOT NULL
),
top_customers AS (
    SELECT ch.c_customer_sk, ch.c_first_name, ch.c_last_name, ch.cd_gender, ch.cd_purchase_estimate
    FROM customer_hierarchy ch
    WHERE ch.rn <= 10
),
popular_items AS (
    SELECT i.i_item_sk, i.i_item_desc, SUM(ss.ss_quantity) AS total_quantity_sold
    FROM store_sales ss
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    WHERE ss.ss_sold_date_sk BETWEEN 
          (SELECT MIN(d.d_date_sk) FROM date_dim d) AND 
          (SELECT MAX(d.d_date_sk) FROM date_dim d)
    GROUP BY i.i_item_sk, i.i_item_desc
    ORDER BY total_quantity_sold DESC
    LIMIT 5
),
returns_data AS (
    SELECT wr.returning_customer_sk, SUM(wr.wr_return_quantity) AS total_returns
    FROM web_returns wr
    GROUP BY wr.returning_customer_sk
),
combined_data AS (
    SELECT tc.c_customer_sk,
           tc.c_first_name,
           tc.c_last_name,
           tc.cd_gender,
           pi.i_item_desc,
           pi.total_quantity_sold,
           COALESCE(rd.total_returns, 0) AS total_returns,
           tc.cd_purchase_estimate - COALESCE(rd.total_returns, 0) AS net_estimate
    FROM top_customers tc
    LEFT JOIN popular_items pi ON pi.i_item_sk IN
        (SELECT DISTINCT wr.wr_item_sk FROM web_returns wr WHERE wr.returning_customer_sk = tc.c_customer_sk)
    LEFT JOIN returns_data rd ON rd.returning_customer_sk = tc.c_customer_sk
)
SELECT cd.c_first_name || ' ' || cd.c_last_name AS customer_name,
       CASE WHEN cd.cd_gender = 'M' THEN 'Mr.' ELSE 'Ms.' END AS salutation,
       cd.total_quantity_sold,
       cd.total_returns,
       cd.net_estimate,
       CASE 
           WHEN cd.net_estimate < 0 THEN 'Negative Estimate'
           WHEN cd.net_estimate >= 1000 THEN 'High Value Customer'
           ELSE 'Regular Customer'
       END AS customer_value_indicator
FROM combined_data cd
WHERE cd.net_estimate IS NOT NULL
ORDER BY cd.net_estimate DESC;
