
WITH RECURSIVE IncomeRanges AS (
    SELECT ib_income_band_sk, ib_lower_bound, ib_upper_bound
    FROM income_band
    WHERE ib_lower_bound IS NOT NULL
  UNION ALL
    SELECT ib.ib_income_band_sk, ib.ib_lower_bound, ib.ib_upper_bound
    FROM income_band ib
    JOIN IncomeRanges ir ON ib.ib_income_band_sk = ir.ib_income_band_sk + 1
),
AggregatedSales AS (
    SELECT 
        c.c_customer_sk,
        cd.cd_gender,
        SUM(ws.ws_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS order_count,
        DENSE_RANK() OVER (PARTITION BY cd.cd_gender ORDER BY SUM(ws.ws_sales_price) DESC) AS sales_rank
    FROM web_sales ws
    JOIN customer c ON ws.ws_ship_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY c.c_customer_sk, cd.cd_gender
),
HighPerformers AS (
    SELECT 
        a.c_customer_sk,
        a.cd_gender,
        a.total_sales,
        a.order_count,
        ir.ib_lower_bound,
        ir.ib_upper_bound
    FROM AggregatedSales a
    LEFT JOIN household_demographics hd ON a.c_customer_sk = hd.hd_demo_sk
    LEFT JOIN IncomeRanges ir ON hd.hd_income_band_sk = ir.ib_income_band_sk
    WHERE a.sales_rank <= 10
)
SELECT 
    hp.c_customer_sk,
    hp.cd_gender,
    hp.total_sales,
    hp.order_count,
    COALESCE(hp.ib_lower_bound || ' - ' || hp.ib_upper_bound, 'No Income Range') AS income_range,
    CASE 
        WHEN hp.total_sales IS NULL THEN 'No sales data'
        WHEN hp.total_sales < 1000 THEN 'Low spender'
        WHEN hp.total_sales BETWEEN 1000 AND 5000 THEN 'Moderate spender'
        ELSE 'High spender'
    END AS spender_category
FROM HighPerformers hp
LEFT JOIN customer_address ca ON hp.c_customer_sk = ca.ca_address_sk
WHERE ca.ca_state IN ('CA', 'NY') OR ca.ca_city LIKE '%York%'
ORDER BY hp.total_sales DESC
LIMIT 50;
