
WITH customer_sales AS (
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, SUM(ws.ws_ext_sales_price) AS total_sales
    FROM customer c
    JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE ws.ws_sold_date_sk BETWEEN 20210101 AND 20211231
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name
), customer_demo AS (
    SELECT cd.cd_demo_sk, cd.cd_gender, cd.cd_marital_status, cd.cd_income_band_sk
    FROM customer_demographics cd
), income_band AS (
    SELECT ib.ib_income_band_sk, ib.ib_lower_bound, ib.ib_upper_bound
    FROM income_band ib
), demographic_info AS (
    SELECT cs.c_customer_sk, cs.total_sales, cd.cd_gender, cd.cd_marital_status, ib.ib_lower_bound, ib.ib_upper_bound
    FROM customer_sales cs
    JOIN customer_demo cd ON cs.c_customer_sk = cd.cd_demo_sk
    JOIN income_band ib ON cd.cd_income_band_sk = ib.ib_income_band_sk
)
SELECT 
    di.cd_gender,
    di.cd_marital_status,
    COUNT(di.c_customer_sk) AS customer_count,
    AVG(di.total_sales) AS avg_sales,
    MIN(di.total_sales) AS min_sales,
    MAX(di.total_sales) AS max_sales
FROM demographic_info di
GROUP BY di.cd_gender, di.cd_marital_status
ORDER BY cd_gender, cd_marital_status;
