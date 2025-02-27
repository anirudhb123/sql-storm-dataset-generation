
WITH RECURSIVE SalesHierarchy AS (
    SELECT 
        s_store_sk, 
        s_store_name, 
        1 AS depth
    FROM store 
    WHERE s_closed_date_sk IS NULL
    UNION ALL
    SELECT 
        s.s_store_sk, 
        CONCAT(sh.s_store_name, ' -> ', s.s_store_name),
        sh.depth + 1
    FROM store s
    JOIN SalesHierarchy sh ON s.s_store_sk = sh.s_store_sk
    WHERE s.s_closed_date_sk IS NULL
),
CustomerDemographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        COUNT(c.c_customer_sk) AS customer_count
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY cd.cd_demo_sk, cd.cd_gender, cd.cd_marital_status, cd.cd_education_status
),
ReturnsAndSales AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_sales,
        COALESCE(SUM(sr.return_quantity), 0) AS total_returns,
        SUM(ws.ws_sales_price * ws.ws_quantity) AS gross_sales
    FROM web_sales ws
    LEFT JOIN store_returns sr ON ws.ws_item_sk = sr.sr_item_sk
    GROUP BY ws.ws_item_sk
)
SELECT 
    sh.s_store_name,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.customer_count,
    ras.total_sales,
    ras.total_returns,
    ras.gross_sales,
    CASE 
        WHEN ras.total_returns > 0 THEN (ras.gross_sales - (ras.total_returns * (SELECT AVG(ws.ws_sales_price) FROM web_sales ws WHERE ws.ws_item_sk = ras.ws_item_sk)))
        ELSE ras.gross_sales
    END AS net_sales
FROM SalesHierarchy sh
JOIN CustomerDemographics cd ON sh.s_store_sk IN (SELECT s_store_sk FROM store WHERE s_closed_date_sk IS NULL)
JOIN ReturnsAndSales ras ON sh.s_store_sk = ras.ws_item_sk
WHERE cd.cd_marital_status = 'M' AND cd.cd_gender = 'F'
ORDER BY net_sales DESC
LIMIT 10;
