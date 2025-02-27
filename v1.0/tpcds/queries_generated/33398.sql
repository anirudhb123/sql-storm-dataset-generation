
WITH RECURSIVE SalesTrends AS (
    SELECT 
        ws_sold_date_sk,
        SUM(ws_net_profit) AS total_profits,
        ROW_NUMBER() OVER (PARTITION BY ws_sold_date_sk ORDER BY ws_sold_date_sk DESC) AS rn
    FROM web_sales
    GROUP BY ws_sold_date_sk
    HAVING SUM(ws_net_profit) IS NOT NULL
),
CustomerIncome AS (
    SELECT 
        cd_demo_sk,
        COUNT(DISTINCT c_customer_sk) AS customer_count,
        SUM(CASE 
            WHEN ib_lower_bound IS NOT NULL AND ib_upper_bound IS NOT NULL 
            THEN 1 ELSE 0 END) AS valid_income_bands
    FROM customer_demographics
    LEFT JOIN household_demographics ON cd_demo_sk = hd_demo_sk
    LEFT JOIN income_band ON hd_income_band_sk = ib_income_band_sk
    GROUP BY cd_demo_sk
),
AggregatedReturns AS (
    SELECT 
        sr_item_sk,
        SUM(sr_return_quantity) AS total_returned,
        SUM(sr_return_amt) AS total_amount_returned
    FROM store_returns
    GROUP BY sr_item_sk
)
SELECT 
    d.d_date AS sales_date,
    COALESCE(st.total_profits, 0) AS total_sales_profits,
    ci.customer_count,
    ai.total_returned,
    ai.total_amount_returned,
    (SELECT COUNT(*) FROM catalog_sales cs WHERE cs.cs_sold_date_sk = d.d_date_sk) AS catalog_sales_count
FROM date_dim d
LEFT JOIN SalesTrends st ON d.d_date_sk = st.ws_sold_date_sk
LEFT JOIN CustomerIncome ci ON ci.cd_demo_sk = (SELECT c_current_cdemo_sk FROM customer WHERE c_first_shipto_date_sk = st.ws_sold_date_sk LIMIT 1)
LEFT JOIN AggregatedReturns ai ON ai.sr_item_sk = (SELECT ws_item_sk FROM web_sales WHERE ws_sold_date_sk = d.d_date_sk LIMIT 1)
WHERE d.d_month_seq = (SELECT MAX(d_month_seq) FROM date_dim WHERE d_current_month = 'Y')
ORDER BY d.d_date;
