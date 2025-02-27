
WITH RankedSales AS (
    SELECT
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_sales_price,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sales_price DESC) AS rank_price
    FROM
        web_sales ws
    WHERE
        ws.ws_ship_date_sk >= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2022)
),
SalesSummary AS (
    SELECT
        i.i_item_id,
        COALESCE(SUM(r.ws_sales_price), 0) AS total_web_sales,
        COUNT(DISTINCT r.ws_order_number) AS order_count 
    FROM 
        item i
    LEFT JOIN RankedSales r ON i.i_item_sk = r.ws_item_sk AND r.rank_price = 1
    GROUP BY
        i.i_item_id
),
CustomerInfo AS (
    SELECT
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_income_band_sk,
        COUNT(DISTINCT ws.ws_order_number) AS customer_order_count
    FROM
        customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_income_band_sk
)
SELECT
    ci.c_customer_id,
    ci.cd_gender,
    ci.cd_income_band_sk,
    ss.total_web_sales,
    ss.order_count,
    CASE 
        WHEN ci.customer_order_count > 10 THEN 'Frequent'
        WHEN ci.customer_order_count BETWEEN 5 AND 10 THEN 'Occasional'
        ELSE 'Rare' 
    END AS purchase_frequency
FROM
    CustomerInfo ci
LEFT JOIN SalesSummary ss ON ci.customer_order_count = ss.order_count
WHERE
    ci.cd_income_band_sk IS NOT NULL 
    AND (ci.cd_gender = 'M' OR ci.cd_gender = 'F')
ORDER BY
    total_web_sales DESC, 
    ci.c_customer_id
LIMIT 100;
