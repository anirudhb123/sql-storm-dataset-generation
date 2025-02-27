
WITH RECURSIVE CustomerCTE AS (
    SELECT c.c_customer_sk, c.c_customer_id, cd.cd_gender, cd.cd_marital_status, 
           cd.cd_purchase_estimate, 1 AS level
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE cd.cd_purchase_estimate IS NOT NULL

    UNION ALL

    SELECT c.c_customer_sk, c.c_customer_id, cd.cd_gender, cd.cd_marital_status, 
           cd.cd_purchase_estimate, cte.level + 1
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN CustomerCTE cte ON c.c_current_cdemo_sk = cte.c_customer_sk
    WHERE cte.level < 5
),
RankedSales AS (
    SELECT ws.ws_item_sk, SUM(ws.ws_sales_price) AS total_sales, 
           ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_sales_price) DESC) AS sales_rank
    FROM web_sales ws
    GROUP BY ws.ws_item_sk
),
FilteredReturns AS (
    SELECT sr_item_sk, SUM(sr_return_quantity) AS total_returns,
           CASE 
               WHEN SUM(sr_return_quantity) > 0 THEN 'High'
               WHEN SUM(sr_return_quantity) IS NULL THEN 'Unknown'
               ELSE 'Low'
           END AS return_rate
    FROM store_returns 
    GROUP BY sr_item_sk
),
FinalReport AS (
    SELECT ca.ca_city, SUM(ws.ws_sales_price) AS total_sales,
           COUNT(DISTINCT c.c_customer_sk) AS customer_count,
           COUNT(DISTINCT sr.sr_ticket_number) AS return_count,
           CASE
               WHEN COUNT(DISTINCT c.c_customer_sk) = 0 THEN NULL
               ELSE (SUM(ws.ws_sales_price) / COUNT(DISTINCT c.c_customer_sk))
           END AS avg_sales_per_customer
    FROM web_sales ws
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    LEFT JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    LEFT JOIN FilteredReturns fr ON ws.ws_item_sk = fr.sr_item_sk
    GROUP BY ca.ca_city
)
SELECT 'Performance Metrics Report' AS report_title,
       ca.ca_city,
       COALESCE(AVG(avg_sales_per_customer), 0) AS average_sales,
       COALESCE(SUM(return_count), 0) AS total_returns,
       SUM(total_sales) AS grand_total_sales,
       CASE 
           WHEN COUNT(DISTINCT c_customer_sk) = 0 THEN 'No Sales'
           ELSE 'Sales Exist'
       END AS sales_status
FROM FinalReport fr
JOIN date_dim dd ON dd.d_date_id = CURRENT_DATE
LEFT JOIN RankedSales rs ON rs.ws_item_sk IN (SELECT DISTINCT ws_item_sk FROM web_sales)
GROUP BY ca.ca_city
HAVING grand_total_sales IS NOT NULL
ORDER BY average_sales DESC NULLS LAST, total_returns DESC;
