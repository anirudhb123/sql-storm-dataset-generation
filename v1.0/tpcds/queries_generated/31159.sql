
WITH RECURSIVE AdultDemographics AS (
    SELECT cd_demo_sk, cd_gender, cd_marital_status, cd_income_band_sk
    FROM customer_demographics
    WHERE cd_gender = 'F'
    UNION ALL
    SELECT cd.cd_demo_sk, cd.cd_gender, cd.cd_marital_status, cd.cd_income_band_sk
    FROM customer_demographics cd
    JOIN AdultDemographics ad ON cd.cd_demo_sk = ad.cd_demo_sk + 1
),
SalesData AS (
    SELECT
        ws.ws_sold_date_sk,
        ws.ws_item_sk,
        ws.ws_quantity,
        ws.ws_sales_price,
        ws.ws_net_paid,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_net_paid DESC) AS rank_sales
    FROM web_sales ws
    WHERE ws.ws_net_paid > 0
),
TotalSales AS (
    SELECT
        ca.ca_state,
        SUM(sd.ws_net_paid) AS total_sales,
        COUNT(DISTINCT cf.c_customer_sk) AS customer_count
    FROM SalesData sd
    JOIN customer cf ON sd.ws_bill_customer_sk = cf.c_customer_sk
    JOIN customer_address ca ON cf.c_current_addr_sk = ca.ca_address_sk
    GROUP BY ca.ca_state
)
SELECT
    ts.ca_state,
    ts.total_sales,
    ts.customer_count,
    CASE
        WHEN ts.total_sales > 10000 THEN 'High'
        WHEN ts.total_sales BETWEEN 5000 AND 10000 THEN 'Medium'
        ELSE 'Low'
    END AS sales_category,
    COALESCE(MAX(ad.cd_marital_status), 'Unknown') AS marital_status
FROM TotalSales ts
LEFT JOIN AdultDemographics ad ON ts.customer_count = ad.cd_demo_sk
WHERE ts.total_sales IS NOT NULL
GROUP BY ts.ca_state, ts.total_sales, ts.customer_count
ORDER BY ts.total_sales DESC
LIMIT 10;
