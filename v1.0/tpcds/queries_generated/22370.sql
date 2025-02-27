
WITH RECURSIVE income_ranges AS (
    SELECT ib_income_band_sk, ib_lower_bound, ib_upper_bound, 
           CASE 
               WHEN ib_lower_bound IS NULL OR ib_upper_bound IS NULL THEN 'Unknown'
               ELSE CONCAT('$', ib_lower_bound, ' - $', ib_upper_bound)
           END AS income_range
    FROM income_band
),
top_customers AS (
    SELECT c.c_customer_id, c.c_first_name, c.c_last_name, 
           SUM(ws.ws_net_profit) AS total_profit,
           ROW_NUMBER() OVER (PARTITION BY c.c_customer_id ORDER BY SUM(ws.ws_net_profit) DESC) AS rn
    FROM customer c
    JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY c.c_customer_id, c.c_first_name, c.c_last_name
),
customer_details AS (
    SELECT cd.cd_gender, cd.cd_marital_status, cd.cd_purchase_estimate,
           c.c_customer_id, c.c_first_name, c.c_last_name
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
sales_summary AS (
    SELECT 
        CASE 
            WHEN ss_sold_date_sk < 0 THEN 'Date Not Available' 
            ELSE CAST(d.d_date AS VARCHAR)
        END AS sold_date,
        ss_store_sk,
        SUM(ss_net_paid) AS total_sales
    FROM store_sales 
    LEFT JOIN date_dim d ON store_sales.ss_sold_date_sk = d.d_date_sk
    GROUP BY ss_store_sk, d.d_date
),
top_stores AS (
    SELECT ss.ss_store_sk, SUM(ss.ss_net_paid) AS total_store_sales,
           RANK() OVER (ORDER BY SUM(ss.ss_net_paid) DESC) AS store_rank
    FROM store_sales ss
    GROUP BY ss.ss_store_sk
)
SELECT DISTINCT 
    c.c_customer_id,
    ct.total_sales,
    cr.income_range,
    COALESCE(ca.ca_city, 'Unknown City') AS city_info,
    t.total_profit,
    CASE 
        WHEN t.total_profit > 1000 THEN 'High Value'
        WHEN t.total_profit BETWEEN 500 AND 1000 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS customer_value_rating
FROM top_customers t
JOIN customer c ON t.c_customer_id = c.c_customer_id
LEFT JOIN customer_details cd ON c.c_customer_id = cd.c_customer_id
LEFT JOIN income_ranges cr ON cd.cd_purchase_estimate BETWEEN cr.ib_lower_bound AND cr.ib_upper_bound
LEFT JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
LEFT JOIN sales_summary ct ON ct.ss_store_sk IN (SELECT s_store_sk FROM store)
LEFT JOIN top_stores ts ON ts.ss_store_sk = ct.ss_store_sk
WHERE (cd.cd_gender = 'F' OR cd.cd_gender IS NULL)
  AND (ct.total_sales IS NOT NULL OR ct.total_sales > 100)
  AND EXISTS (SELECT 1 FROM web_sales ws WHERE ws.ws_bill_customer_sk = c.c_customer_sk AND ws.ws_net_profit > 0)
ORDER BY t.total_profit DESC, c.c_last_name;
