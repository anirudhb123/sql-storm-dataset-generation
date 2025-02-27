
WITH RECURSIVE SalesCTE AS (
    SELECT ws_order_number, 
           SUM(ws_ext_sales_price) AS total_sales, 
           COUNT(ws_item_sk) AS total_items,
           ws_sold_date_sk
    FROM web_sales
    GROUP BY ws_order_number, ws_sold_date_sk
),
CTE_Customer AS (
    SELECT c.c_customer_sk, 
           c.c_first_name || ' ' || c.c_last_name AS full_name,
           cd.cd_gender, 
           cd.cd_marital_status, 
           cd.cd_purchase_estimate,
           ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS rn
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
SalesSummary AS (
    SELECT s.ss_store_sk, 
           SUM(s.ss_ext_sales_price) AS total_store_sales,
           ROW_NUMBER() OVER (PARTITION BY s.ss_store_sk ORDER BY SUM(s.ss_ext_sales_price) DESC) AS store_rank
    FROM store_sales s
    WHERE s.ss_sold_date_sk = (SELECT MAX(ss_sold_date_sk) FROM store_sales)
    GROUP BY s.ss_store_sk
)
SELECT 
    cc.full_name,
    cc.cd_gender,
    COALESCE(s.total_sales, 0) AS web_sales_total,
    COALESCE(ss.total_store_sales, 0) AS store_sales_total,
    MAX(ws_sold_date_sk) AS last_web_sale_date,
    ds.d_year AS sale_year,
    ds.d_month AS sale_month
FROM CTE_Customer cc
LEFT JOIN SalesCTE s ON cc.c_customer_sk = s.ws_order_number
LEFT JOIN SalesSummary ss ON ss.ss_store_sk = cc.c_current_addr_sk
JOIN date_dim ds ON ds.d_date_sk = s.ws_sold_date_sk
WHERE cc.rn <= 5 
    AND (cc.cd_purchase_estimate > 500 OR cc.cd_marital_status = 'S')
ORDER BY cc.cd_gender, web_sales_total DESC;
