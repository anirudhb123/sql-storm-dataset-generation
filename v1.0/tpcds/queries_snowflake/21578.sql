
WITH RECURSIVE IncomeRange AS (
    SELECT ib_income_band_sk, ib_lower_bound, ib_upper_bound
    FROM income_band
    WHERE ib_income_band_sk IS NOT NULL
    UNION ALL
    SELECT ib.ib_income_band_sk, ib.ib_lower_bound, ib.ib_upper_bound
    FROM income_band ib
    JOIN IncomeRange ir ON ib.ib_income_band_sk = ir.ib_income_band_sk + 1
), 
CustomerInfo AS (
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name,
           COALESCE(cd.cd_gender, 'N/A') AS gender,
           COALESCE(cd.cd_marital_status, 'Unknown') AS marital_status,
           ca.ca_city AS city,
           CASE 
               WHEN cd.cd_purchase_estimate IS NULL THEN 'Estimate Not Available'
               WHEN cd.cd_purchase_estimate < 1000 THEN 'Low Buyer'
               WHEN cd.cd_purchase_estimate BETWEEN 1000 AND 5000 THEN 'Medium Buyer'
               ELSE 'High Buyer'
           END AS buyer_category
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
SalesData AS (
    SELECT ws.ws_bill_customer_sk, 
           SUM(ws.ws_net_paid) AS total_sales,
           COUNT(DISTINCT ws.ws_order_number) AS total_orders,
           ROW_NUMBER() OVER (PARTITION BY ws.ws_bill_customer_sk ORDER BY SUM(ws.ws_net_paid) DESC) AS sales_rank
    FROM web_sales ws
    GROUP BY ws.ws_bill_customer_sk
),
ReturnData AS (
    SELECT cr_returning_customer_sk,
           SUM(cr_return_amount) AS total_return_amount,
           COUNT(DISTINCT cr_order_number) AS total_returns
    FROM catalog_returns
    GROUP BY cr_returning_customer_sk
),
FinalReport AS (
    SELECT ci.c_customer_sk, ci.c_first_name, ci.c_last_name,
           ci.gender, ci.marital_status, ci.city,
           COALESCE(sd.total_sales, 0) AS total_sales,
           COALESCE(rd.total_return_amount, 0) AS total_return_amount,
           ci.buyer_category,
           (COALESCE(sd.total_sales, 0) - COALESCE(rd.total_return_amount, 0)) AS net_spending
    FROM CustomerInfo ci
    LEFT JOIN SalesData sd ON ci.c_customer_sk = sd.ws_bill_customer_sk
    LEFT JOIN ReturnData rd ON ci.c_customer_sk = rd.cr_returning_customer_sk
)
SELECT fr.c_customer_sk, fr.c_first_name, fr.c_last_name, 
       fr.gender, fr.marital_status, fr.city,
       fr.total_sales, fr.total_return_amount, fr.buyer_category, fr.net_spending,
       CASE 
           WHEN fr.net_spending IS NULL THEN 'No Activity'
           WHEN fr.net_spending < 0 THEN 'Loss'
           WHEN fr.net_spending BETWEEN 0 AND 500 THEN 'Low Profit'
           WHEN fr.net_spending BETWEEN 501 AND 1000 THEN 'Moderate Profit'
           ELSE 'High Profit'
       END AS profitability_category
FROM FinalReport fr
WHERE fr.city IS NOT NULL
ORDER BY fr.net_spending DESC
LIMIT 100;
