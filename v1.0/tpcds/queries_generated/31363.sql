
WITH RECURSIVE SalesHierarchy AS (
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, 
           SUM(ws.ws_net_profit) AS total_sales
    FROM customer c
    JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE ws.ws_sold_date_sk = (SELECT MAX(d.d_date_sk) FROM date_dim d)
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name
    HAVING SUM(ws.ws_net_profit) > 1000

    UNION ALL

    SELECT ch.c_customer_sk, ch.c_first_name, ch.c_last_name,
           sh.total_sales * 0.9
    FROM SalesHierarchy sh
    JOIN customer ch ON sh.c_customer_sk = ch.c_current_cdemo_sk
    WHERE ch.c_current_cdemo_sk IS NOT NULL
)
SELECT sr.c_customer_sk, sr.c_first_name, sr.c_last_name, sr.total_sales, 
       DENSE_RANK() OVER (ORDER BY sr.total_sales DESC) AS sales_rank,
       CASE WHEN sr.total_sales IS NULL THEN 'No Sales' ELSE 'Sales Made' END AS sales_status
FROM SalesHierarchy sr
LEFT JOIN customer_demographics cd ON sr.c_customer_sk = cd.cd_demo_sk
LEFT JOIN store_sales ss ON sr.c_customer_sk = ss.ss_customer_sk
WHERE cd.cd_gender = 'F' 
  AND cd.cd_marital_status = 'M'
  AND sr.total_sales IS NOT NULL
ORDER BY sales_rank
FETCH NEXT 10 ROWS ONLY;
