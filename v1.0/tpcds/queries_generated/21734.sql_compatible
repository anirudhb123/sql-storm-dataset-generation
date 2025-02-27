
WITH RECURSIVE AddressHierarchy AS (
    SELECT ca_address_sk, ca_city, ca_state, ca_country, 1 AS hierarchy_level
    FROM customer_address
    WHERE ca_city IS NOT NULL

    UNION ALL

    SELECT a.ca_address_sk, a.ca_city, a.ca_state, a.ca_country, ah.hierarchy_level + 1
    FROM customer_address a
    JOIN AddressHierarchy ah ON a.ca_state = ah.ca_state
    WHERE a.ca_city IS NOT NULL AND a.ca_address_sk <> ah.ca_address_sk
),
CustomerWithIncome AS (
    SELECT c.c_customer_sk, cd.cd_gender, cd.cd_marital_status, 
           cd.cd_credit_rating, ib.ib_lower_bound, ib.ib_upper_bound,
           CASE 
               WHEN cd.cd_purchase_estimate IS NULL THEN 'Unknown'
               ELSE 'Known' 
           END AS purchase_status
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
    LEFT JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
),
TopWarehouseSales AS (
    SELECT w.warehouse_name, SUM(ss.ss_net_profit) AS total_profit
    FROM store_sales ss
    JOIN warehouse w ON ss.ss_store_sk = w.w_warehouse_sk
    GROUP BY w.warehouse_name
    ORDER BY total_profit DESC
    LIMIT 10
),
SalesWithRowNumbers AS (
    SELECT ws.*, 
           ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sales_price DESC) AS row_num,
           DENSE_RANK() OVER (ORDER BY ws.ws_ext_sales_price DESC) AS sales_rank
    FROM web_sales ws
    WHERE ws.ws_sales_price IS NOT NULL
)
SELECT 
    ch.c_customer_sk, ch.cd_gender, ch.purchase_status, ah.ca_city, ah.ca_country, 
    COALESCE(ws_rank.row_num, 0) AS web_sales_rank,
    COALESCE(ws_rank.sales_rank, 'N/A') AS dense_sales_rank,
    tws.total_profit
FROM CustomerWithIncome ch
LEFT JOIN AddressHierarchy ah ON ch.c_customer_sk = ah.ca_address_sk
LEFT JOIN SalesWithRowNumbers ws_rank ON ch.c_customer_sk = ws_rank.ws_bill_customer_sk
LEFT JOIN TopWarehouseSales tws ON tws.warehouse_name LIKE '%' || ch.cd_credit_rating || '%'
WHERE (ch.ib_lower_bound <= ALL(SELECT DISTINCT r.ir_lower_bound FROM income_band r WHERE r.ib_income_band_sk IS NOT NULL)
       OR ch.ib_upper_bound >= ALL(SELECT DISTINCT r.ir_upper_bound FROM income_band r WHERE r.ib_income_band_sk IS NOT NULL))
AND (ah.ca_country IS NULL OR ah.ca_country != 'Unknown')
ORDER BY ch.c_customer_sk, tws.total_profit DESC;
