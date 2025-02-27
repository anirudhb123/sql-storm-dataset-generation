
WITH RECURSIVE OrderedReturns AS (
    SELECT sr_item_sk, SUM(sr_return_quantity) AS total_returned
    FROM store_returns
    WHERE sr_returned_date_sk <= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY sr_item_sk
),
CustomerDemographics AS (
    SELECT cd_gender, cd_marital_status, cd_purchase_estimate, cd_credit_rating
    FROM customer_demographics
    WHERE cd_purchase_estimate > (SELECT AVG(cd_purchase_estimate) FROM customer_demographics WHERE cd_credit_rating IS NOT NULL)
),
MaxReturnedItem AS (
    SELECT sr_item_sk
    FROM OrderedReturns
    WHERE total_returned = (SELECT MAX(total_returned) FROM OrderedReturns)
),
DateBoundaries AS (
    SELECT d_date_sk, d_year, d_moy, d_dow, d_day_name
    FROM date_dim
    WHERE d_date BETWEEN '2023-01-01' AND '2023-12-31'
),
Summary AS (
    SELECT COUNT(DISTINCT c.c_customer_id) AS total_customers, 
           SUM(ws_ext_sales_price) AS total_sales,
           AVG(ws_net_profit) AS avg_net_profit
    FROM web_sales ws
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN CustomerDemographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN MaxReturnedItem mri ON ws.ws_item_sk = mri.sr_item_sk
    JOIN DateBoundaries db ON ws.ws_sold_date_sk = db.d_date_sk
    WHERE cd.cd_gender = 'F' 
      AND db.d_dow IN (0, 6) -- Weekend sales
),
FinalMetrics AS (
    SELECT *,
           CASE 
               WHEN total_sales > 10000 THEN 'High Performer'
               WHEN total_sales BETWEEN 5000 AND 10000 THEN 'Medium Performer'
               ELSE 'Low Performer' 
           END AS performance_category
    FROM Summary
)
SELECT total_customers, total_sales, avg_net_profit, performance_category
FROM FinalMetrics
WHERE (avg_net_profit IS NOT NULL AND total_sales IS NOT NULL)
  OR (avg_net_profit IS NULL AND total_sales IS NULL)
UNION ALL
SELECT COUNT(DISTINCT sr_item_sk) AS total_customers, 
       SUM(sr_return_amt_inc_tax) AS total_sales,
       AVG(sr_net_loss) AS avg_net_profit, 
       'Returns Analysis' AS performance_category
FROM store_returns
WHERE sr_item_sk IN (SELECT sr_item_sk FROM MaxReturnedItem)
  AND sr_returned_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023)
      AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
GROUP BY sr_item_sk
ORDER BY total_sales DESC
LIMIT 10;
