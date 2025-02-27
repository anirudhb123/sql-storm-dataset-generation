
WITH RECURSIVE SalesHierarchy AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        COALESCE(ws.ws_net_paid, 0) AS total_web_sales,
        COALESCE(cs.cs_net_paid, 0) AS total_catalog_sales,
        COALESCE(ss.ss_net_paid, 0) AS total_store_sales,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY 
            COALESCE(ws.ws_net_paid, 0) + COALESCE(cs.cs_net_paid, 0) + COALESCE(ss.ss_net_paid, 0) DESC) as sales_rank
    FROM customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN catalog_sales cs ON c.c_customer_sk = cs.cs_bill_customer_sk
    LEFT JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
),
AggregateSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(total_web_sales) AS total_web_sales,
        SUM(total_catalog_sales) AS total_catalog_sales,
        SUM(total_store_sales) AS total_store_sales
    FROM SalesHierarchy sh
    JOIN customer c ON sh.c_customer_sk = c.c_customer_sk
    WHERE sh.sales_rank <= 10
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name
),
CustomerDemographic AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        hd.hd_income_band_sk,
        hd.hd_buy_potential
    FROM customer_demographics cd
    LEFT JOIN household_demographics hd ON cd.cd_demo_sk = hd.hd_demo_sk
)
SELECT 
    a.c_customer_sk,
    a.c_first_name,
    a.c_last_name,
    a.total_web_sales,
    a.total_catalog_sales,
    a.total_store_sales,
    cd.cd_gender,
    cd.cd_marital_status,
    ib.ib_lower_bound,
    ib.ib_upper_bound
FROM AggregateSales a
LEFT JOIN CustomerDemographic cd ON a.c_customer_sk = cd.cd_demo_sk
LEFT JOIN income_band ib ON cd.hd_income_band_sk = ib.ib_income_band_sk
WHERE (cd.cd_gender = 'F' OR cd.cd_gender IS NULL)
  AND a.total_web_sales > (
      SELECT AVG(total_web_sales) 
      FROM AggregateSales
  )
ORDER BY total_store_sales DESC, total_catalog_sales DESC, total_web_sales DESC
OFFSET 0 ROWS FETCH NEXT 50 ROWS ONLY;
