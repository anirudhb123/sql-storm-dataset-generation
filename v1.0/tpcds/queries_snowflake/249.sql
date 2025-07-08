
WITH customer_info AS (
    SELECT c.c_customer_sk,
           c.c_first_name,
           c.c_last_name,
           cd.cd_gender,
           cd.cd_marital_status,
           hd.hd_income_band_sk,
           hd.hd_buy_potential,
           SUM(ws.ws_sales_price) AS total_sales
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
    JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE c.c_birth_year >= 1970
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status, hd.hd_income_band_sk, hd.hd_buy_potential
), ranked_customers AS (
    SELECT *,
           RANK() OVER (PARTITION BY hd_income_band_sk ORDER BY total_sales DESC) AS sales_rank
    FROM customer_info
), top_customers AS (
    SELECT *
    FROM ranked_customers
    WHERE sales_rank <= 10
)
SELECT t.c_customer_sk,
       t.c_first_name,
       t.c_last_name,
       t.cd_gender,
       t.cd_marital_status,
       t.hd_income_band_sk,
       t.hd_buy_potential,
       COALESCE(t.total_sales, 0) AS total_sales,
       COALESCE(store_sales_counts.store_sales_count, 0) AS store_sales_count,
       COALESCE(catalog_sales_counts.catalog_sales_count, 0) AS catalog_sales_count
FROM top_customers t
LEFT JOIN (
    SELECT ss_customer_sk, COUNT(*) AS store_sales_count
    FROM store_sales
    GROUP BY ss_customer_sk
) store_sales_counts ON store_sales_counts.ss_customer_sk = t.c_customer_sk
LEFT JOIN (
    SELECT cs_bill_customer_sk, COUNT(*) AS catalog_sales_count
    FROM catalog_sales
    GROUP BY cs_bill_customer_sk
) catalog_sales_counts ON catalog_sales_counts.cs_bill_customer_sk = t.c_customer_sk
LEFT JOIN store s ON s.s_store_sk = (SELECT ss.ss_store_sk
                                      FROM store_sales ss
                                      WHERE ss.ss_customer_sk = t.c_customer_sk 
                                      ORDER BY ss.ss_sold_date_sk DESC LIMIT 1)
ORDER BY t.hd_income_band_sk, total_sales DESC;
