
WITH RECURSIVE CustomerReturnCTE AS (
    SELECT
        sr_returning_customer_sk,
        sr_return_quantity,
        COALESCE(SUM(sr_return_quantity), 0) AS total_returned,
        ROW_NUMBER() OVER (PARTITION BY sr_returning_customer_sk ORDER BY sr_return_quantity DESC) AS rn
    FROM store_returns
    GROUP BY sr_returning_customer_sk, sr_item_sk
),
AggregatedReturns AS (
    SELECT
        returning_c.c_customer_id,
        COALESCE(SUM(returned.total_returned), 0) AS total_return_amount,
        COUNT(DISTINCT returned.sr_ticket_number) AS total_tickets
    FROM customer returning_c
    LEFT JOIN CustomerReturnCTE returned ON returning_c.c_customer_sk = returned.sr_returning_customer_sk
    GROUP BY returning_c.c_customer_id
),
DemographicsWithRent AS (
    SELECT
        demo.cd_gender,
        demo.cd_marital_status,
        ROUND(AVG(returned.total_return_amount), 2) AS average_return_amount
    FROM customer_demographics demo
    JOIN AggregatedReturns returned ON demo.cd_demo_sk IN (
        SELECT DISTINCT c.c_current_cdemo_sk 
        FROM customer c 
        WHERE c.c_customer_id IS NOT NULL AND c.c_customer_id NOT LIKE '%test%')
    GROUP BY demo.cd_gender, demo.cd_marital_status
)
SELECT 
    demo.cd_gender,
    demo.cd_marital_status,
    COALESCE(demo.average_return_amount, 0) AS avg_return_amount,
    CASE
        WHEN demo.cd_marital_status = 'M' THEN 'Married'
        WHEN demo.cd_marital_status = 'S' THEN 'Single'
        ELSE 'Unknown'
    END AS marital_status_label
FROM DemographicsWithRent demo
FULL OUTER JOIN (
    SELECT
        c.c_gender,
        COUNT(1) AS customer_count,
        MAX(cd_purchase_estimate) AS max_purchase_estimation
    FROM customer_demo cd
    JOIN customer c ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY c.c_gender
) AS gender_counts ON demo.cd_gender = gender_counts.c_gender
ORDER BY avg_return_amount DESC, marital_status_label ASC
LIMIT 100 OFFSET 10;
