
WITH RECURSIVE address_tree AS (
    SELECT ca_address_sk, ca_address_id, ca_street_name, ca_city, ca_state, ca_zip, ca_country
    FROM customer_address
    WHERE ca_city IS NOT NULL
    UNION ALL
    SELECT a.ca_address_sk, a.ca_address_id, CONCAT(at.ca_street_name, ' & ', a.ca_street_name) AS ca_street_name,
           CONCAT(at.ca_city, ' | ', a.ca_city) AS ca_city, 
           COALESCE(at.ca_state, a.ca_state) AS ca_state, 
           CASE WHEN at.ca_zip IS NULL THEN a.ca_zip ELSE at.ca_zip END AS ca_zip,
           CASE WHEN at.ca_country IS NULL THEN a.ca_country ELSE at.ca_country END AS ca_country
    FROM customer_address a
    JOIN address_tree at ON a.ca_zip = at.ca_zip AND a.ca_city = at.ca_city
    WHERE a.ca_address_sk <> at.ca_address_sk
),
customer_data AS (
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, 
           d.d_date, 
           LEAD(d.d_date) OVER (PARTITION BY c.c_customer_sk ORDER BY d.d_date) AS next_date,
           COALESCE(cd.cd_purchase_estimate, 0) AS purchase_estimate, 
           ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY d.d_date) AS rn
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN date_dim d ON c.c_first_sales_date_sk = d.d_date_sk
),
sales_metrics AS (
    SELECT ws.ws_bill_customer_sk, 
           SUM(ws.ws_net_paid) AS total_sales, 
           AVG(ws.ws_net_profit) AS avg_net_profit,
           COUNT(DISTINCT ws.ws_order_number) AS total_orders 
    FROM web_sales ws
    GROUP BY ws.ws_bill_customer_sk
),
final_report AS (
    SELECT cd.c_first_name, cd.c_last_name, 
           COALESCE(sm.total_sales, 0) AS total_sales, 
           COALESCE(sm.avg_net_profit, 0) AS avg_net_profit,
           cd.purchase_estimate,
           COALESCE(at.ca_city, 'Unknown') AS ca_city,
           DENSE_RANK() OVER (ORDER BY COALESCE(sm.total_sales, 0) DESC) AS sales_rank
    FROM customer_data cd
    LEFT JOIN sales_metrics sm ON cd.c_customer_sk = sm.ws_bill_customer_sk
    LEFT JOIN address_tree at ON cd.c_customer_sk = at.ca_address_sk
    WHERE cd.rn < 10 OR cd.purchase_estimate > 1000
)
SELECT DISTINCT fr.c_first_name, fr.c_last_name, fr.total_sales, fr.avg_net_profit, fr.purchase_estimate,
       CASE WHEN fr.sales_rank IS NULL THEN 'Unranked' ELSE CAST(fr.sales_rank AS VARCHAR) END AS sales_ranking
FROM final_report fr
WHERE fr.total_sales IS NOT NULL OR fr.avg_net_profit IS NOT NULL
ORDER BY fr.sales_rank ASC NULLS LAST;
