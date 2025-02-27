
WITH customer_info AS (
    SELECT c.c_customer_sk,
           c.c_customer_id,
           cd.cd_gender,
           cd.cd_marital_status,
           IFNULL(SUM(ss.ss_quantity), 0) AS total_store_sales,
           IFNULL(SUM(ws.ws_quantity), 0) AS total_web_sales,
           COALESCE(MAX(cs.cs_sales_price), 0) AS max_catalog_sale_price,
           COUNT(sr.sr_ticket_number) AS total_store_returns
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN catalog_sales cs ON c.c_customer_sk = cs.cs_bill_customer_sk
    LEFT JOIN store_returns sr ON c.c_customer_sk = sr.sr_customer_sk
    GROUP BY c.c_customer_sk, c.c_customer_id, cd.cd_gender, cd.cd_marital_status
),
date_summary AS (
    SELECT d.d_date_sk,
           d.d_year,
           d.d_month_seq,
           SUM(CASE WHEN d.d_current_day = 'Y' THEN 1 ELSE 0 END) AS is_today,
           COUNT(*) AS total_days
    FROM date_dim d
    GROUP BY d.d_date_sk, d.d_year, d.d_month_seq
)
SELECT ci.c_customer_id,
       ci.cd_gender,
       ci.cd_marital_status,
       ds.d_year,
       ds.d_month_seq,
       ds.is_today,
       CASE 
           WHEN ci.total_store_sales > 100 THEN 'High Spender'
           WHEN ci.total_web_sales > 100 THEN 'Web Enthusiast'
           ELSE 'Casual Shopper'
       END AS shopper_type,
       ROUND(AVG(ci.max_catalog_sale_price), 2) AS avg_max_catalog_sale_price,
       SUM(COALESCE(ci.total_store_sales, 0) + COALESCE(ci.total_web_sales, 0)) AS overall_sales,
       COUNT(DISTINCT ci.total_store_returns) AS unique_returns
FROM customer_info ci
JOIN date_summary ds ON ds.total_days > 30
WHERE ci.total_store_sales > (SELECT AVG(total_store_sales) FROM customer_info)
      OR ci.total_web_sales > (SELECT AVG(total_web_sales) FROM customer_info)
      AND (ci.cd_gender IS NOT NULL OR ci.cd_marital_status IS NOT NULL)
GROUP BY ci.c_customer_id, ci.cd_gender, ci.cd_marital_status, ds.d_year, ds.d_month_seq, ds.is_today
HAVING overall_sales < 1000
ORDER BY ds.d_year DESC, ds.d_month_seq DESC, shopper_type;
