
WITH RankedCustomers AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_marital_status,
        cd.cd_gender,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_marital_status ORDER BY c.c_customer_sk) AS rnk
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
SalesSummary AS (
    SELECT
        ws.ws_bill_customer_sk,
        SUM(ws.ws_net_paid) AS total_spent,
        COUNT(ws.ws_order_number) AS order_count
    FROM web_sales ws
    GROUP BY ws.ws_bill_customer_sk
),
CustomerPerformance AS (
    SELECT
        rc.c_customer_sk,
        rc.c_first_name,
        rc.c_last_name,
        ss.total_spent,
        ss.order_count,
        CASE 
            WHEN ss.total_spent IS NULL THEN 'No purchases'
            WHEN ss.total_spent < 100 THEN 'Low spender'
            WHEN ss.total_spent BETWEEN 100 AND 500 THEN 'Medium spender'
            ELSE 'High spender'
        END AS spending_category
    FROM RankedCustomers rc
    LEFT JOIN SalesSummary ss ON rc.c_customer_sk = ss.ws_bill_customer_sk
)
SELECT 
    cp.c_customer_sk,
    cp.c_first_name,
    cp.c_last_name,
    COALESCE(cp.total_spent, 0) AS total_spent,
    COALESCE(cp.order_count, 0) AS order_count,
    cp.spending_category,
    (SELECT COUNT(*) FROM store_sales ss WHERE ss.ss_customer_sk = cp.c_customer_sk AND ss.ss_net_paid IS NOT NULL) AS store_order_count,
    (SELECT COUNT(*) FROM catalog_sales cs WHERE cs.cs_bill_customer_sk = cp.c_customer_sk AND cs.cs_net_paid IS NOT NULL) AS catalog_order_count,
    CASE 
        WHEN cp.order_count IS NOT NULL AND cp.order_count > 0 THEN 
            (SELECT SUM(r.r_return_quantity) FROM web_returns r WHERE r.wr_returning_customer_sk = cp.c_customer_sk)
        ELSE 0
    END AS total_returns,
    CASE 
        WHEN cp.order_count IS NULL THEN 'No data available'
        ELSE 'Data available'
    END AS data_status
FROM CustomerPerformance cp
WHERE cp.spending_category != 'No purchases' 
    OR cp.order_count IS NOT NULL
ORDER BY cp.spending_category ASC, cp.total_spent DESC;
