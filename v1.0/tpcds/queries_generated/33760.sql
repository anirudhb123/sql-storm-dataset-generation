
WITH RECURSIVE recent_sales AS (
    SELECT ws_item_sk, 
           SUM(ws_quantity) AS total_quantity, 
           SUM(ws_net_paid) AS total_sales, 
           ws_ship_date_sk
    FROM web_sales
    GROUP BY ws_item_sk, ws_ship_date_sk
    HAVING SUM(ws_quantity) > 100
    UNION ALL
    SELECT ws.ws_item_sk, 
           rs.total_quantity + ws.ws_quantity AS total_quantity, 
           rs.total_sales + ws.ws_net_paid AS total_sales, 
           ws.ws_ship_date_sk
    FROM web_sales ws
    JOIN recent_sales rs ON ws.ws_item_sk = rs.ws_item_sk AND ws.ws_ship_date_sk > rs.ws_ship_date_sk
    WHERE ws.ws_ship_date_sk < (SELECT MAX(ws_ship_date_sk) FROM web_sales)  -- To limit recursion
),
top_items AS (
    SELECT rs.ws_item_sk,
           rs.total_quantity,
           rs.total_sales,
           DENSE_RANK() OVER (ORDER BY rs.total_sales DESC) AS sales_rank
    FROM recent_sales rs
),
demographic_info AS (
    SELECT cd.cd_demo_sk,
           cd.cd_gender,
           cd.cd_marital_status,
           cb.c_birth_year,
           cb.c_birth_month,
           cb.c_birth_day,
           COALESCE(cd.cd_dep_count, 0) AS dep_count,
           COALESCE(cd.cd_dep_employed_count, 0) AS dep_employed_count,
           COALESCE(cd.cd_dep_college_count, 0) AS dep_college_count
    FROM customer cb
    JOIN customer_demographics cd ON cb.c_current_cdemo_sk = cd.cd_demo_sk
),
sales_demos AS (
    SELECT ti.ws_item_sk,
           ti.total_quantity,
           ti.total_sales,
           di.*
    FROM top_items ti
    JOIN web_sales ws ON ti.ws_item_sk = ws.ws_item_sk
    LEFT JOIN demographic_info di ON ws.ws_bill_customer_sk = di.cd_demo_sk
)
SELECT s.ws_item_sk,
       s.total_quantity,
       s.total_sales,
       di.cd_gender,
       di.cd_marital_status,
       di.dep_count,
       di.dep_employed_count,
       di.dep_college_count
FROM sales_demos s
JOIN store_sales ss ON s.ws_item_sk = ss.ss_item_sk
WHERE s.total_quantity > 200
  AND (di.cd_gender = 'F' OR di.cd_marital_status = 'M')
  AND EXISTS (
      SELECT 1
      FROM store_returns sr
      WHERE sr.sr_item_sk = s.ws_item_sk
        AND sr.sr_return_quantity > 0
  )
  AND s.total_sales > (
      SELECT AVG(total_sales)
      FROM sales_demos
  )
ORDER BY s.total_sales DESC
LIMIT 10;
