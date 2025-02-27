
WITH SalesSummary AS (
    SELECT 
        ws_bill_customer_sk,
        COUNT(ws_order_number) AS total_orders,
        SUM(ws_net_paid_inc_tax) AS total_sales,
        MAX(ws_sold_date_sk) AS last_order_date
    FROM web_sales
    WHERE ws_sold_date_sk >= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY ws_bill_customer_sk
), 
DemographicAnalysis AS (
    SELECT 
        cd_demo_sk,
        cd_gender,
        cd_marital_status,
        AVG(cd_purchase_estimate) AS avg_purchase_estimate
    FROM customer_demographics
    GROUP BY cd_demo_sk, cd_gender, cd_marital_status
), 
LastOrderInfo AS (
    SELECT 
        customer.c_customer_sk,
        COALESCE(ss.total_orders, 0) AS total_orders, 
        COALESCE(ss.total_sales, 0) AS total_sales,
        DATEDIFF(CURRENT_DATE, (SELECT MAX(d_date) FROM date_dim WHERE d_date_sk = ss.last_order_date)) AS days_since_last_order
    FROM customer
    LEFT JOIN SalesSummary ss ON customer.c_customer_sk = ss.ws_bill_customer_sk
)
SELECT 
    lo.customer_sk,
    d.gender,
    d.marital_status,
    lo.total_orders,
    lo.total_sales,
    lo.days_since_last_order,
    CASE 
        WHEN lo.days_since_last_order < 30 THEN 'Recent Customer'
        WHEN lo.days_since_last_order BETWEEN 30 AND 90 THEN 'Inactive Customer'
        ELSE 'Long-term Lapse'
    END AS customer_status
FROM LastOrderInfo lo
JOIN DemographicAnalysis d ON lo.customer_sk = d.cd_demo_sk
WHERE lo.total_sales > 500
  AND d.avg_purchase_estimate IS NOT NULL
ORDER BY lo.total_sales DESC
LIMIT 100;
