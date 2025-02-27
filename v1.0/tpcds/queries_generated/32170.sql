
WITH RECURSIVE IncomeBands AS (
    SELECT ib_income_band_sk, 
           ib_lower_bound, 
           ib_upper_bound,
           ROW_NUMBER() OVER (ORDER BY ib_income_band_sk) AS row_num
    FROM income_band
),
CustomerInfo AS (
    SELECT c.c_customer_sk, 
           c.c_customer_id,
           cd.cd_gender,
           cd.cd_marital_status,
           cd.cd_income_band_sk,
           COALESCE(hd.hd_income_band_sk, NULL) AS hd_income_band_sk,
           dev_ranking,
           COUNT(DISTINCT CASE WHEN ws.ws_order_number IS NOT NULL THEN ws.ws_order_number END) AS total_orders
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN household_demographics hd ON cd.cd_demo_sk = hd.hd_demo_sk
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY c.c_customer_sk, c.c_customer_id, cd.cd_gender, cd.cd_marital_status, hd.hd_income_band_sk
),
AggregatedSales AS (
    SELECT ws.ws_bill_customer_sk,
           SUM(ws.ws_ext_sales_price) AS total_sales,
           SUM(ws.ws_ext_tax) AS total_tax,
           COUNT(ws.ws_order_number) AS order_count,
           RANK() OVER (PARTITION BY ws.ws_bill_customer_sk ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS sales_rank
    FROM web_sales ws
    GROUP BY ws.ws_bill_customer_sk
)
SELECT ci.c_customer_id,
       ci.cd_gender,
       ci.cd_marital_status,
       ib.ib_lower_bound,
       ib.ib_upper_bound,
       COALESCE(asales.total_sales, 0) AS total_sales,
       COALESCE(asales.total_tax, 0) AS total_tax,
       asales.order_count,
       COUNT(DISTINCT ws.ws_order_number) AS web_order_count
FROM CustomerInfo ci
LEFT JOIN IncomeBands ib ON ci.cd_income_band_sk = ib.ib_income_band_sk
LEFT JOIN AggregatedSales asales ON ci.c_customer_sk = asales.ws_bill_customer_sk
LEFT JOIN web_sales ws ON ci.c_customer_sk = ws.ws_bill_customer_sk
WHERE (ci.total_orders > 0 AND asales.order_count IS NULL) OR (asales.total_sales > 5000)
GROUP BY ci.c_customer_id, ci.cd_gender, ci.cd_marital_status, ib.ib_lower_bound, ib.ib_upper_bound, asales.total_sales, asales.total_tax, asales.order_count
ORDER BY ib.ib_lower_bound DESC, total_sales DESC;
