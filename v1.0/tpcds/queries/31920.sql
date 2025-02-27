WITH RECURSIVE CustomerHierarchy AS (
    SELECT c_customer_sk, c_first_name, c_last_name, c_birth_country, c_current_cdemo_sk, 1 AS level
    FROM customer
    WHERE c_birth_country IS NOT NULL
    UNION ALL
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, c.c_birth_country, c.c_current_cdemo_sk, ch.level + 1
    FROM customer c
    JOIN CustomerHierarchy ch ON c.c_current_cdemo_sk = ch.c_current_cdemo_sk
    WHERE ch.level < 3
),
SalesData AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM web_sales ws
    WHERE ws.ws_sold_date_sk BETWEEN 2451985 AND 2452041  
    GROUP BY ws.ws_item_sk
),
CustomerStats AS (
    SELECT 
        cd.cd_gender,
        COUNT(DISTINCT c.c_customer_sk) AS customer_count,
        AVG(cd.cd_purchase_estimate) AS avg_purchase_estimate,
        SUM(CASE WHEN cd.cd_marital_status = 'M' THEN 1 ELSE 0 END) AS married_count
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE cd.cd_gender IN ('M', 'F')
    GROUP BY cd.cd_gender
),
ReturnsData AS (
    SELECT 
        sr_item_sk, 
        SUM(sr_return_quantity) AS total_returns
    FROM store_returns
    GROUP BY sr_item_sk
),
FinalReport AS (
    SELECT 
        c.c_first_name, 
        c.c_last_name, 
        ch.level,
        cs.customer_count,
        cs.avg_purchase_estimate,
        COALESCE(sd.total_sales, 0) AS total_sales,
        COALESCE(rd.total_returns, 0) AS total_returns
    FROM CustomerHierarchy ch
    JOIN customer c ON ch.c_customer_sk = c.c_customer_sk
    LEFT JOIN CustomerStats cs ON cs.cd_gender = 'F'
    LEFT JOIN SalesData sd ON sd.ws_item_sk = ch.c_current_cdemo_sk  
    LEFT JOIN ReturnsData rd ON rd.sr_item_sk = ch.c_current_cdemo_sk
)
SELECT 
    f.c_first_name, 
    f.c_last_name, 
    f.level, 
    f.customer_count, 
    f.avg_purchase_estimate, 
    f.total_sales, 
    f.total_returns
FROM FinalReport f
WHERE f.total_sales > 1000 OR f.total_returns > 0
ORDER BY f.level, f.customer_count DESC;