
WITH RECURSIVE CustomerHierarchy AS (
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, c.c_current_cdemo_sk,
           cd.cd_gender, cd.cd_marital_status, cd.cd_dep_count,
           1 AS Level
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE cd.cd_marital_status = 'M'
    
    UNION ALL
    
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, c.c_current_cdemo_sk,
           cd.cd_gender, cd.cd_marital_status, cd.cd_dep_count,
           ch.Level + 1
    FROM customer c
    JOIN CustomerHierarchy ch ON c.c_current_cdemo_sk = ch.c_customer_sk
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE cd.cd_marital_status = 'S' AND cd.cd_dep_count = ch.Level
),
TotalSales AS (
    SELECT ws_bill_customer_sk,
           SUM(ws_ext_sales_price) AS Total_Sales
    FROM web_sales
    WHERE ws_sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2022)
    GROUP BY ws_bill_customer_sk
),
QualifiedCustomers AS (
    SELECT DISTINCT ch.c_customer_sk,
                    ch.c_first_name,
                    ch.c_last_name,
                    ch.cd_gender,
                    ts.Total_Sales
    FROM CustomerHierarchy ch
    LEFT JOIN TotalSales ts ON ch.c_customer_sk = ts.ws_bill_customer_sk
    WHERE ts.Total_Sales IS NOT NULL AND ch.Level > 1
)
SELECT qc.c_customer_sk, 
       qc.c_first_name, 
       qc.c_last_name, 
       qc.cd_gender, 
       NVL(qc.Total_Sales, 0) AS Total_Sales
FROM QualifiedCustomers qc
ORDER BY qc.Total_Sales DESC
FETCH FIRST 10 ROWS ONLY;

