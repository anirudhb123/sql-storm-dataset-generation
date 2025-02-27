
WITH CustomerStats AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS purchase_rank,
        COALESCE(NULLIF(SUBSTRING(c.c_email_address, POSITION('@' IN c.c_email_address) + 1), 'gmail.com'), 'notgmail.com') AS email_provider
    FROM customer c
    INNER JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
HighValueCustomers AS (
    SELECT 
        cs.c_customer_sk,
        cs.c_first_name,
        cs.c_last_name,
        cs.cd_gender,
        cs.cd_marital_status,
        cs.cd_purchase_estimate
    FROM CustomerStats cs
    WHERE cs.purchase_rank <= 10
),
ItemReturns AS (
    SELECT 
        sr_item_sk,
        SUM(sr_return_quantity) AS total_returns,
        SUM(sr_return_amt) AS total_return_amount
    FROM store_returns 
    GROUP BY sr_item_sk
),
WebReturns AS (
    SELECT 
        wr_item_sk,
        SUM(wr_return_quantity) AS web_total_returns,
        SUM(wr_return_amt) AS web_total_return_amount
    FROM web_returns 
    GROUP BY wr_item_sk
),
CombinedReturns AS (
    SELECT 
        itm.inv_item_sk,
        COALESCE(sr.total_returns, 0) AS total_store_returns,
        COALESCE(wr.web_total_returns, 0) AS total_web_returns,
        COALESCE(sr.total_return_amount, 0) AS total_store_return_amount,
        COALESCE(wr.web_total_return_amount, 0) AS total_web_return_amount
    FROM inventory itm
    LEFT JOIN ItemReturns sr ON itm.inv_item_sk = sr.sr_item_sk
    LEFT JOIN WebReturns wr ON itm.inv_item_sk = wr.wr_item_sk
)
SELECT 
    c.c_customer_sk,
    c.c_first_name,
    c.c_last_name,
    SUM(cr.total_store_returns + cr.total_web_returns) AS total_returns,
    AVG(DISTINCT cr.total_store_return_amount + cr.total_web_return_amount) AS avg_return_amount,
    (SELECT 
         AVG(cd.cd_dep_count) 
     FROM customer_demographics cd 
     WHERE cd.cd_demo_sk IN (SELECT c.c_current_cdemo_sk FROM customer c WHERE c.c_customer_sk = c_customer_sk)
    ) AS avg_dependents,
    COUNT(DISTINCT r.r_reason_desc) AS unique_return_reasons
FROM HighValueCustomers c
LEFT JOIN CombinedReturns cr ON cr.inv_item_sk IN (
        SELECT ws_item_sk FROM web_sales WHERE ws_bill_customer_sk = c.c_customer_sk
        UNION ALL
        SELECT cs_item_sk FROM catalog_sales WHERE cs_bill_customer_sk = c.c_customer_sk
  )
LEFT JOIN reason r ON r.r_reason_sk IN (
        SELECT sr_reason_sk FROM store_returns sr WHERE sr.sr_customer_sk = c.c_customer_sk
        UNION ALL
        SELECT wr_reason_sk FROM web_returns wr WHERE wr_returning_customer_sk = c.c_customer_sk
    )
GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name
HAVING SUM(cr.total_store_returns + cr.total_web_returns) > 0
ORDER BY total_returns DESC
LIMIT 20;
