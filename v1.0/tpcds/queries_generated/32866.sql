
WITH RECURSIVE Income_Band_Data AS (
    SELECT ib_income_band_sk, 
           ib_lower_bound, 
           ib_upper_bound,
           0 AS level
    FROM income_band
    WHERE ib_lower_bound IS NOT NULL AND ib_upper_bound IS NOT NULL
    UNION ALL
    SELECT ib.ib_income_band_sk,
           ib.ib_lower_bound,
           ib.ib_upper_bound,
           id.level + 1
    FROM income_band ib
    JOIN Income_Band_Data id ON id.ib_income_band_sk = ib.ib_income_band_sk
    WHERE id.level < 5
),
Ranked_Customers AS (
    SELECT c.c_customer_id,
           cd.cd_demographics_sk,
           cd.cd_gender,
           cd.cd_marital_status,
           cd.cd_purchase_estimate,
           ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS purchase_rank
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
Sales_Aggregates AS (
    SELECT ws.ws_bill_customer_sk,
           SUM(ws.ws_net_profit) AS total_net_profit,
           COUNT(ws.ws_order_number) AS total_sales
    FROM web_sales ws
    WHERE ws.ws_sold_date_sk BETWEEN 20230101 AND 20231231
    GROUP BY ws.ws_bill_customer_sk
),
Customer_Sales AS (
    SELECT ca.ca_address_id,
           sa.total_net_profit,
           cb.c_first_name,
           cb.c_last_name,
           cb.purchase_rank,
           CASE WHEN sa.total_sales IS NULL THEN 0 ELSE sa.total_sales END AS sales_count,
           CASE WHEN cb.cd_marital_status = 'M' THEN 'Married' ELSE 'Single' END AS marital_status
    FROM Ranked_Customers cb
    LEFT JOIN Sales_Aggregates sa ON cb.c_customer_id = sa.ws_bill_customer_sk
    LEFT JOIN customer_address ca ON cb.c_current_addr_sk = ca.ca_address_sk
    WHERE cb.purchase_rank <= 5
)
SELECT csa.ca_address_id,
       SUM(csa.total_net_profit) AS total_profit,
       AVG(csa.sales_count) AS average_sales,
       COUNT(DISTINCT csa.c_first_name || ' ' || csa.c_last_name) AS unique_customers
FROM Customer_Sales csa
WHERE csa.marital_status = 'Married'
GROUP BY csa.ca_address_id
HAVING SUM(csa.total_net_profit) > 5000
ORDER BY total_profit DESC
LIMIT 10;
