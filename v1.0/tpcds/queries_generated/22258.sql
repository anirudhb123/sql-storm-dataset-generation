
WITH RECURSIVE IncomeStats AS (
    SELECT 
        ib_income_band_sk,
        (ib_lower_bound + ib_upper_bound) / 2 AS average_income,
        1 AS depth
    FROM 
        income_band
    WHERE 
        ib_lower_bound IS NOT NULL AND ib_upper_bound IS NOT NULL
    UNION ALL
    SELECT 
        ib_income_band_sk,
        (average_income + (2 * depth)) / (depth + 1) AS average_income,
        depth + 1
    FROM 
        IncomeStats i
    JOIN income_band b ON i.ib_income_band_sk = b.ib_income_band_sk
    WHERE 
        depth < 5
),
CustomerOverview AS (
    SELECT 
        DISTINCT c.c_customer_sk, 
        c.c_first_name, 
        c.c_last_name, 
        cd.cd_gender, 
        cd.cd_marital_status,
        cd.cd_credit_rating,
        COALESCE(CAST(cd.cd_purchase_estimate AS VARCHAR), 'Unknown') AS purchase_estimate,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY c.c_first_name) AS rn
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        c.c_birth_year IS NOT NULL AND (cd.cd_gender IS NOT NULL OR cd.cd_marital_status IS NOT NULL)
),
SalesData AS (
    SELECT
        ws_customer_sk,
        SUM(ws_net_profit) AS total_profit,
        AVG(ws_net_paid) AS avg_paid,
        COUNT(DISTINCT ws_order_number) AS total_orders,
        RANK() OVER (PARTITION BY ws_customer_sk ORDER BY SUM(ws_net_profit) DESC) AS rank
    FROM 
        web_sales
    GROUP BY 
        ws_customer_sk
),
UnionedSales AS (
    SELECT 
        ws_customer_sk AS customer_sk,
        SUM(ws_net_profit) AS combined_profit
    FROM 
        web_sales
    GROUP BY 
        ws_customer_sk
    UNION 
    SELECT 
        cs_bill_customer_sk AS customer_sk,
        SUM(cs_net_profit) AS combined_profit
    FROM 
        catalog_sales
    GROUP BY 
        cs_bill_customer_sk
)
SELECT 
    co.c_customer_sk,
    co.c_first_name,
    co.c_last_name,
    s.total_profit,
    u.combined_profit,
    (CASE 
         WHEN s.total_profit IS NULL THEN 0
         ELSE s.total_profit
     END) AS safe_profit,
    (CASE 
         WHEN cd.cd_credit_rating = 'Excellent' AND u.combined_profit > 1000 
         THEN 'Premium Customer' 
         WHEN cd.cd_credit_rating IS NULL 
         THEN 'Unknown Credit'
         ELSE 'Standard Customer'
     END) AS customer_type
FROM 
    CustomerOverview co
LEFT JOIN 
    SalesData s ON co.c_customer_sk = s.ws_customer_sk
LEFT JOIN 
    UnionedSales u ON co.c_customer_sk = u.customer_sk
WHERE 
    co.rn <= 10 AND
    (s.total_profit IS NOT NULL OR u.combined_profit > 0)
ORDER BY 
    co.c_last_name, 
    co.c_first_name;
