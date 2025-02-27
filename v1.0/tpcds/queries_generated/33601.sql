
WITH RECURSIVE CustomerHierarchy AS (
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, c.c_current_cdemo_sk, 1 AS level
    FROM customer c
    WHERE c.c_current_cdemo_sk IS NOT NULL
    UNION ALL
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, c.c_current_cdemo_sk, ch.level + 1
    FROM customer c
    JOIN CustomerHierarchy ch ON c.c_current_cdemo_sk = ch.c_current_cdemo_sk
),
TotalSales AS (
    SELECT 
        cs.cs_customer_sk,
        SUM(cs.cs_net_paid_inc_tax) AS total_sales,
        COUNT(*) AS order_count,
        AVG(cs.cs_net_paid_inc_tax) AS avg_order_value
    FROM catalog_sales cs
    GROUP BY cs.cs_customer_sk
),
CustomerInfo AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        ci.c_first_name,
        ci.c_last_name,
        COALESCE(ts.total_sales, 0) AS total_sales,
        COALESCE(ts.order_count, 0) AS order_count,
        COALESCE(ts.avg_order_value, 0) AS avg_order_value
    FROM customer_demographics cd
    LEFT JOIN CustomerHierarchy ci ON cd.cd_demo_sk = ci.c_current_cdemo_sk
    LEFT JOIN TotalSales ts ON ts.cs_customer_sk = ci.c_customer_sk
)
SELECT 
    ci.cd_gender,
    ci.cd_marital_status,
    COUNT(DISTINCT ci.c_first_name || ' ' || ci.c_last_name) AS total_customers,
    AVG(ci.total_sales) AS avg_sales_value,
    MAX(ci.avg_order_value) AS max_order_value,
    MIN(ci.total_sales) AS min_sales
FROM CustomerInfo ci
WHERE ci.total_sales > 100
GROUP BY ci.cd_gender, ci.cd_marital_status
ORDER BY total_customers DESC
FETCH FIRST 10 ROWS ONLY;
