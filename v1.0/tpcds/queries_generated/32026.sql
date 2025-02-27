
WITH RECURSIVE income_brackets AS (
    SELECT ib_income_band_sk, ib_lower_bound, ib_upper_bound
    FROM income_band
    WHERE ib_lower_bound IS NOT NULL
    UNION ALL
    SELECT ib.ib_income_band_sk, ib.ib_lower_bound, ib.ib_upper_bound
    FROM income_band ib
    JOIN income_brackets ib_r ON ib_r.ib_income_band_sk = ib.ib_income_band_sk + 1
),
customer_summary AS (
    SELECT 
        c.c_customer_sk,
        c.c_current_cdemo_sk,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_sales_price) AS total_sales,
        AVG(ws.ws_sales_price) AS avg_order_value
    FROM customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY c.c_customer_sk, c.c_current_cdemo_sk
),
demographic_summary AS (
    SELECT
        cd.cd_demo_sk,
        cd.cd_gender,
        COUNT(DISTINCT cs.cs_order_number) AS catalog_orders,
        SUM(cs.cs_sales_price) AS catalog_sales,
        SUM(CASE WHEN cs.cs_sales_price < 50 THEN 1 ELSE 0 END) AS low_value_orders
    FROM customer_demographics cd
    LEFT JOIN catalog_sales cs ON cd.cd_demo_sk = cs.cs_bill_cdemo_sk
    GROUP BY cd.cd_demo_sk, cd.cd_gender
)
SELECT 
    cs.c_customer_sk,
    CASE 
        WHEN cd.cd_gender IS NULL THEN 'Unknown'
        ELSE cd.cd_gender
    END AS gender,
    cs.total_orders,
    cs.total_sales,
    cs.avg_order_value,
    ds.catalog_orders,
    ds.catalog_sales,
    ds.low_value_orders,
    ib.ib_lower_bound,
    ib.ib_upper_bound
FROM customer_summary cs
FULL OUTER JOIN demographic_summary ds ON cs.c_current_cdemo_sk = ds.cd_demo_sk
LEFT JOIN income_brackets ib ON (cs.total_sales BETWEEN ib.ib_lower_bound AND ib.ib_upper_bound)
WHERE (cs.total_orders IS NOT NULL OR ds.catalog_orders IS NOT NULL)
AND (cs.avg_order_value > 100 OR ds.catalog_sales > 1000)
ORDER BY cs.total_sales DESC, ds.catalog_orders DESC;
