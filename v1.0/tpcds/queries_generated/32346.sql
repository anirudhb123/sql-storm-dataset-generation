
WITH RECURSIVE sales_cte AS (
    SELECT ws_cdemo_sk, SUM(ws_ext_sales_price) AS total_sales
    FROM web_sales
    GROUP BY ws_cdemo_sk
    UNION ALL
    SELECT cs_cdemo_sk, total_sales + SUM(cs_ext_sales_price)
    FROM catalog_sales cs
    JOIN sales_cte ss ON cs.cs_bill_cdemo_sk = ss.ws_cdemo_sk
    GROUP BY cs_cs_cdemo_sk
)
SELECT ca_state,
       COUNT(DISTINCT c.c_customer_id) AS customer_count,
       AVG(cd_purchase_estimate) AS avg_purchase_estimate,
       SUM(ws_ext_sales_price) AS total_web_sales,
       COALESCE(SUM(ss_ext_sales_price), 0) AS total_store_sales,
       ROW_NUMBER() OVER (PARTITION BY ca_state ORDER BY total_web_sales DESC) AS sales_rank
FROM customer_address ca
LEFT JOIN customer c ON ca.ca_address_sk = c.c_current_addr_sk
LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
LEFT JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
LEFT JOIN sales_cte s ON c.c_current_cdemo_sk = s.ws_cdemo_sk
WHERE cd.cd_gender = 'F'
  AND cd.cd_marital_status = 'M'
  AND ca_state IS NOT NULL
GROUP BY ca_state
HAVING COUNT(DISTINCT c.c_customer_id) > 0
ORDER BY total_web_sales DESC;
