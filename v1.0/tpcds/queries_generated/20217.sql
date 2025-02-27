
WITH CustomerSales AS (
    SELECT 
        c.c_customer_id,
        SUM(COALESCE(ss.ss_ext_sales_price, 0) + COALESCE(ws.ws_ext_sales_price, 0) + COALESCE(cs.cs_ext_sales_price, 0)) AS total_sales,
        COUNT(DISTINCT ss.ss_ticket_number) AS store_transaction_count,
        COUNT(DISTINCT ws.ws_order_number) AS web_transaction_count,
        COUNT(DISTINCT cs.cs_order_number) AS catalog_transaction_count
    FROM 
        customer c
    LEFT JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN 
        catalog_sales cs ON c.c_customer_sk = cs.cs_bill_customer_sk
    GROUP BY 
        c.c_customer_id
),
CustomerDemographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        ib.ib_income_band_sk,
        (SELECT COUNT(*) 
         FROM household_demographics hd 
         WHERE hd.hd_income_band_sk = ib.ib_income_band_sk) AS household_count
    FROM 
        customer_demographics cd
    LEFT JOIN 
        income_band ib ON cd.cd_demo_sk = ib.ib_income_band_sk
)
SELECT 
    cs.c_customer_id,
    cs.total_sales,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.household_count,
    CASE 
        WHEN cs.total_sales > 1000 THEN 'High Value'
        WHEN cs.total_sales BETWEEN 500 AND 1000 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS customer_value_segment,
    RANK() OVER (PARTITION BY cd.cd_marital_status ORDER BY cs.total_sales DESC) AS rank_within_marital
FROM 
    CustomerSales cs
JOIN 
    CustomerDemographics cd ON cs.c_customer_id = cd.cd_demo_sk
WHERE 
    (cd.cd_gender = 'F' AND cd.cd_marital_status = 'M') OR (cd.cd_gender = 'M' AND cd.cd_marital_status = 'S')
ORDER BY 
    customer_value_segment, cs.total_sales DESC
LIMIT 100;

WITH RECURSIVE must_not_have AS (
  SELECT cd_demo_sk, 0 AS depth FROM customer_demographics cd WHERE cd_marital_status = 'M' AND cd_gender = 'F'
  UNION ALL
  SELECT 
      cd.cd_demo_sk,
      m.depth + 1 
  FROM must_not_have m
  JOIN customer_demographics cd ON cd.cd_demo_sk = m.cd_demo_sk
  WHERE cd.cd_gender IS NULL AND m.depth < 10
)
SELECT DISTINCT cd.cd_demo_sk 
FROM must_not_have m
JOIN customer_demographics cd ON m.cd_demo_sk = cd.cd_demo_sk;

SELECT 
    COALESCE(a.ca_city, 'Unknown') AS Addressed_City,
    COUNT(DISTINCT cs.c_customer_id) AS Number_of_Customers
FROM 
    customer_address a
LEFT JOIN 
    CustomerSales cs ON a.ca_address_sk = cs.c_customer_id
WHERE 
    a.ca_state IS NOT NULL 
    AND (a.ca_country LIKE 'U%' OR a.ca_country IS NULL)
GROUP BY 
    a.ca_city;
