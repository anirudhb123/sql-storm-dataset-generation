
WITH customer_sales AS (
  SELECT 
    c.c_customer_id,
    SUM(ws.ws_ext_sales_price) AS total_web_sales,
    SUM(cs.cs_ext_sales_price) AS total_catalog_sales,
    SUM(ss.ss_ext_sales_price) AS total_store_sales,
    COUNT(DISTINCT ws.ws_order_number) AS web_order_count,
    COUNT(DISTINCT cs.cs_order_number) AS catalog_order_count,
    COUNT(DISTINCT ss.ss_ticket_number) AS store_order_count
  FROM 
    customer c
  LEFT JOIN 
    web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
  LEFT JOIN 
    catalog_sales cs ON c.c_customer_sk = cs.cs_bill_customer_sk
  LEFT JOIN 
    store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
  GROUP BY 
    c.c_customer_id
),
demographic_summary AS (
  SELECT 
    cd.education_status,
    COUNT(DISTINCT cs.c_customer_id) AS customer_count,
    SUM(cs.total_web_sales) AS total_web_sales,
    SUM(cs.total_catalog_sales) AS total_catalog_sales,
    SUM(cs.total_store_sales) AS total_store_sales
  FROM 
    customer_sales cs
  JOIN 
    customer_demographics cd ON cs.c_customer_id = cd.cd_demo_sk
  GROUP BY 
    cd.education_status
)
SELECT 
  ds.education_status,
  ds.customer_count,
  ds.total_web_sales,
  ds.total_catalog_sales,
  ds.total_store_sales,
  (ds.total_web_sales + ds.total_catalog_sales + ds.total_store_sales) AS grand_total_sales
FROM 
  demographic_summary ds
ORDER BY 
  grand_total_sales DESC
LIMIT 10;
