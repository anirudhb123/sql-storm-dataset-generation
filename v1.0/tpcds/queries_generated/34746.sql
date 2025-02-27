
WITH RECURSIVE CustomerHierarchy AS (
    SELECT c_customer_sk, c_first_name, c_last_name, c_current_cdemo_sk, 1 AS level
    FROM customer
    WHERE c_current_cdemo_sk IS NOT NULL
    UNION ALL
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, c.c_current_cdemo_sk, ch.level + 1
    FROM customer c
    INNER JOIN CustomerHierarchy ch ON c.c_current_cdemo_sk = ch.c_current_cdemo_sk
),
AggregatedSales AS (
    SELECT 
        ws_cdemo_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS total_orders
    FROM web_sales
    GROUP BY ws_cdemo_sk
),
FlaggedDemographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        CASE 
            WHEN cd.cd_credit_rating IS NULL THEN 'Unrated'
            ELSE cd.cd_credit_rating
        END AS credit_rating
    FROM customer_demographics cd
    WHERE cd.cd_purchase_estimate > 1000
),
TopStores AS (
    SELECT 
        s_store_sk,
        s_store_name,
        SUM(ss_ext_sales_price) AS total_sales
    FROM store_sales ss
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    GROUP BY s_store_sk, s_store_name
    ORDER BY total_sales DESC
    LIMIT 10
)
SELECT 
    ch.c_first_name,
    ch.c_last_name,
    ad.total_sales,
    ad.total_orders,
    fd.cd_gender,
    fd.cd_marital_status,
    fd.credit_rating,
    ts.s_store_name
FROM CustomerHierarchy ch
JOIN AggregatedSales ad ON ch.c_current_cdemo_sk = ad.ws_cdemo_sk
JOIN FlaggedDemographics fd ON ch.c_current_cdemo_sk = fd.cd_demo_sk
LEFT JOIN TopStores ts ON ad.total_sales > (SELECT AVG(total_sales) FROM AggregatedSales)
WHERE ch.level = 1 OR fd.cd_gender = 'F'
ORDER BY ad.total_sales DESC, ch.c_last_name;
