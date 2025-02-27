
WITH CustomerSales AS (
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, 
           SUM(ws.ws_ext_sales_price) AS total_web_sales,
           SUM(cs.cs_ext_sales_price) AS total_catalog_sales,
           SUM(ss.ss_ext_sales_price) AS total_store_sales
    FROM customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    LEFT JOIN catalog_sales cs ON c.c_customer_sk = cs.cs_ship_customer_sk
    LEFT JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name
),
TopCustomers AS (
    SELECT c.c_first_name, c.c_last_name, 
           (COALESCE(total_web_sales, 0) + COALESCE(total_catalog_sales, 0) + COALESCE(total_store_sales, 0)) AS total_sales
    FROM CustomerSales c
    ORDER BY total_sales DESC
    LIMIT 10
)
SELECT tc.c_first_name, tc.c_last_name, 
       cd.cd_gender, cd.cd_marital_status, cd.cd_education_status,
       COUNT( DISTINCT wr.wr_order_number) AS total_web_returns,
       COUNT(DISTINCT cr.cr_order_number) AS total_catalog_returns,
       COUNT(DISTINCT sr.sr_ticket_number) AS total_store_returns
FROM TopCustomers tc
JOIN customer_demographics cd ON tc.c_customer_sk = cd.cd_demo_sk
LEFT JOIN web_returns wr ON tc.c_customer_sk = wr.wr_returning_customer_sk
LEFT JOIN catalog_returns cr ON tc.c_customer_sk = cr.cr_returning_customer_sk
LEFT JOIN store_returns sr ON tc.c_customer_sk = sr.sr_customer_sk
GROUP BY tc.c_first_name, tc.c_last_name, cd.cd_gender, cd.cd_marital_status, cd.cd_education_status
ORDER BY total_sales DESC, tc.c_last_name ASC;
