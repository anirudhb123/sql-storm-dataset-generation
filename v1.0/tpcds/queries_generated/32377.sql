
WITH RECURSIVE customer_sales AS (
    SELECT c.c_customer_sk, 
           c.c_first_name, 
           c.c_last_name, 
           ws.ws_order_number,
           ws.ws_sales_price,
           w.w_warehouse_name,
           RANK() OVER (PARTITION BY c.c_customer_sk ORDER BY ws.ws_sales_price DESC) AS sales_rank
    FROM web_sales ws
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    WHERE ws.ws_sold_date_sk >= 2400
), top_sales AS (
    SELECT c_customer_sk, 
           c_first_name, 
           c_last_name, 
           SUM(ws_sales_price) AS total_sales
    FROM customer_sales 
    WHERE sales_rank <= 5
    GROUP BY c_customer_sk, c_first_name, c_last_name
), demographics AS (
    SELECT cd.cd_gender, 
           hd.hd_income_band_sk, 
           COUNT(*) AS customer_count
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN household_demographics hd ON c.c_customer_sk = hd.hd_demo_sk
    GROUP BY cd.cd_gender, hd.hd_income_band_sk
)
SELECT ts.c_first_name, 
       ts.c_last_name, 
       ts.total_sales, 
       d.cd_gender, 
       d.hd_income_band_sk,
       CASE 
           WHEN d.hd_income_band_sk IS NULL THEN 'Unknown'
           ELSE CAST(d.hd_income_band_sk AS VARCHAR)
       END AS income_band
FROM top_sales ts
LEFT JOIN demographics d ON ts.c_customer_sk = d.c_customer_sk
WHERE ts.total_sales > (SELECT AVG(total_sales) FROM top_sales)
ORDER BY ts.total_sales DESC
LIMIT 100
UNION ALL
SELECT c.c_first_name, 
       c.c_last_name, 
       0 AS total_sales, 
       'N/A' AS cd_gender, 
       'N/A' AS hd_income_band_sk
FROM customer c
WHERE c.c_customer_sk NOT IN (SELECT c_customer_sk FROM top_sales)
ORDER BY total_sales DESC, c_last_name, c_first_name;
