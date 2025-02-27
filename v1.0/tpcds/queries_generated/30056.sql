
WITH RECURSIVE DateHierarchy AS (
    SELECT d_date_sk, d_date, d_year, d_month_seq, d_week_seq, 0 AS level
    FROM date_dim
    WHERE d_date = '2023-01-01'
    UNION ALL
    SELECT dd.d_date_sk, dd.d_date, dd.d_year, dd.d_month_seq, dd.d_week_seq, level + 1
    FROM date_dim dd
    JOIN DateHierarchy dh ON dd.d_date_sk = dh.d_date_sk + 1
    WHERE dd.d_date BETWEEN '2023-01-01' AND '2023-12-31'
),
CustomerInfo AS (
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender,
           cd.cd_marital_status, cd.cd_purchase_estimate,
           ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS PurchaseRank
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
SalesSummary AS (
    SELECT ws_bill_customer_sk, SUM(ws_ext_sales_price) AS TotalSales,
           COUNT(DISTINCT ws_order_number) AS OrderCount, 
           SUM(ws_ext_tax) AS TotalTax
    FROM web_sales
    WHERE ws_sold_date_sk IN (SELECT d_date_sk FROM DateHierarchy)
    GROUP BY ws_bill_customer_sk
),
CustomerSales AS (
    SELECT ci.c_customer_sk, ci.c_first_name, ci.c_last_name, ss.TotalSales, ss.OrderCount, ss.TotalTax
    FROM CustomerInfo ci
    LEFT JOIN SalesSummary ss ON ci.c_customer_sk = ss.ws_bill_customer_sk
    WHERE ci.PurchaseRank <= 10
)
SELECT cs.c_first_name, cs.c_last_name, 
       COALESCE(cs.TotalSales, 0) AS TotalSales,
       COALESCE(cs.OrderCount, 0) AS OrderCount,
       COALESCE(cs.TotalTax, 0) AS TotalTax,
       CASE WHEN cs.TotalSales IS NULL THEN 'No Sales' ELSE 'Sales Data Available' END AS SalesStatus
FROM CustomerSales cs
LEFT JOIN customer_address ca ON cs.c_customer_sk = ca.ca_address_sk
WHERE ca.ca_state = 'CA'
ORDER BY cs.TotalSales DESC
LIMIT 20;
