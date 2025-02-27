
WITH ranked_sales AS (
    SELECT
        ws.bill_customer_sk,
        ws_item_sk,
        SUM(ws_net_paid) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws.bill_customer_sk ORDER BY SUM(ws_net_paid) DESC) AS sales_rank
    FROM web_sales ws
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    WHERE ws.ws_sold_date_sk BETWEEN 2459635 AND 2459645 -- Dates corresponding to the month of February 2023
    AND i.i_current_price > 50
    GROUP BY ws.bill_customer_sk, ws_item_sk
), max_sales AS (
    SELECT
        bill_customer_sk,
        MAX(total_sales) AS max_total_sales
    FROM ranked_sales
    GROUP BY bill_customer_sk
), customer_details AS (
    SELECT 
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating,
        CASE 
            WHEN cd.cd_dep_count > 2 THEN 'High Dependency'
            WHEN cd.cd_dep_count IS NULL THEN 'Unknown Dependency'
            ELSE 'Low Dependency'
        END AS dependency_level
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
), customer_summary AS (
    SELECT 
        cd.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating,
        coalesce(ms.max_total_sales, 0) AS max_sales
    FROM customer_details cd
    LEFT JOIN max_sales ms ON cd.c_customer_id = ms.bill_customer_sk
)
SELECT 
    cs.c_customer_id,
    cs.cd_gender,
    cs.cd_marital_status,
    cs.cd_purchase_estimate,
    cs.cd_credit_rating,
    cs.max_sales,
    CASE 
        WHEN cs.max_sales > 1000 THEN 'Top Customer'
        WHEN cs.max_sales BETWEEN 500 AND 1000 THEN 'Mid-tier Customer'
        ELSE 'Low-tier Customer'
    END AS customer_tier
FROM customer_summary cs
WHERE cs.cd_marital_status = 'M' 
AND cs.max_sales IS NOT NULL
ORDER BY cs.max_sales DESC;

```
