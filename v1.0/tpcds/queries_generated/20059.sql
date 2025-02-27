
WITH RankedSales AS (
    SELECT 
        ws_item_sk,
        ws_order_number,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_sales_price DESC) AS sales_rank
    FROM web_sales
    WHERE ws_sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_week_seq = (SELECT d_week_seq FROM date_dim WHERE d_date = CURRENT_DATE - INTERVAL '7 days'))
),
TopSales AS (
    SELECT 
        rs.ws_item_sk, 
        rs.ws_order_number, 
        rs.sales_rank,
        COALESCE(cs_ext_sales_price, 0) AS cs_ext_sales_price,
        COALESCE(ss_ext_sales_price, 0) AS ss_ext_sales_price
    FROM RankedSales rs
    LEFT JOIN catalog_sales cs ON rs.ws_item_sk = cs.cs_item_sk AND rs.ws_order_number = cs.cs_order_number
    LEFT JOIN store_sales ss ON rs.ws_item_sk = ss.ss_item_sk AND rs.ws_order_number = ss.ss_ticket_number
    WHERE rs.sales_rank < 5
),
SalesSummary AS (
    SELECT
        ts.ws_item_sk,
        SUM(ts.cs_ext_sales_price) AS total_catalog_sales,
        SUM(ts.ss_ext_sales_price) AS total_store_sales,
        SUM(ts.cs_ext_sales_price + ts.ss_ext_sales_price) AS total_combined_sales
    FROM TopSales ts
    GROUP BY ts.ws_item_sk
),
IncomeBands AS (
    SELECT 
        ib_income_band_sk,
        CASE 
            WHEN ib_lower_bound IS NULL OR ib_upper_bound IS NULL THEN 'Unknown Band'
            ELSE CONCAT('$', ib_lower_bound::text, ' - $', ib_upper_bound::text)
        END AS income_band_range
    FROM income_band
    WHERE ib_lower_bound IS NOT NULL OR ib_upper_bound IS NOT NULL
),
CustomerDemographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        COUNT(DISTINCT c.c_customer_sk) AS num_customers
    FROM customer c 
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY cd.cd_demo_sk, cd.cd_gender
)
SELECT 
    ss.ws_item_sk,
    ib.income_band_range,
    SUM(ss.total_combined_sales) AS total_sales,
    cd.cd_gender,
    cd.num_customers
FROM SalesSummary ss
JOIN IncomeBands ib ON ss.ws_item_sk = ib.ib_income_band_sk 
LEFT JOIN CustomerDemographics cd ON cd.cd_demo_sk = (SELECT MAX(cd_demo_sk) FROM customer WHERE c_current_cdemo_sk IS NOT NULL)
WHERE total_sales IS NOT NULL
GROUP BY ss.ws_item_sk, ib.income_band_range, cd.cd_gender, cd.num_customers
HAVING SUM(ss.total_combined_sales) > 1000
ORDER BY total_sales DESC;
