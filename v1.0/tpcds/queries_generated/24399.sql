
WITH CustomerReturns AS (
    SELECT cr_returning_customer_sk,
           SUM(cr_return_quantity) AS total_item_returned,
           SUM(cr_return_amt) AS total_returned_amt,
           COUNT(DISTINCT cr_order_number) AS total_orders_returned,
           ROW_NUMBER() OVER (PARTITION BY cr_returning_customer_sk ORDER BY SUM(cr_return_amt) DESC) AS rank
    FROM catalog_returns
    GROUP BY cr_returning_customer_sk
),
CustomerDemographics AS (
    SELECT cd_demo_sk,
           cd_gender,
           cd_marital_status,
           cd_income_band_sk,
           COALESCE(cd_purchase_estimate, 0) AS purchase_estimate,
           CASE WHEN cd_dep_count > 0 THEN 'Has Dependents' ELSE 'No Dependents' END AS dependents_status
    FROM customer_demographics
),
RankedCustomers AS (
    SELECT c.c_customer_id,
           c.c_first_name,
           c.c_last_name,
           cd.mdemo_sk,
           cd.ccd_marital_status,
           cd.dependents_status,
           cr.total_item_returned,
           cr.total_returned_amt,
           cr.total_orders_returned
    FROM customer c
    LEFT JOIN CustomerDemographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN CustomerReturns cr ON c.c_customer_sk = cr.cr_returning_customer_sk
    WHERE cr.total_item_returned IS NOT NULL OR c.c_customer_sk IN (
        SELECT DISTINCT cr2.cr_returning_customer_sk 
        FROM catalog_returns cr2 WHERE cr2.cr_return_quantity < 0
    )
)
SELECT r.c_customer_id,
       r.c_first_name,
       r.c_last_name,
       r.dependents_status,
       COALESCE(r.total_item_returned, 0) AS total_item_returned,
       COALESCE(r.total_returned_amt, 0) AS total_returned_amt,
       CASE 
           WHEN r.rank IS NULL THEN 'Not Ranked' 
           ELSE 'Ranked ' || r.rank 
       END AS return_rank
FROM RankedCustomers r
ORDER BY r.total_returned_amt DESC, r.c_last_name ASC
LIMIT 100;
