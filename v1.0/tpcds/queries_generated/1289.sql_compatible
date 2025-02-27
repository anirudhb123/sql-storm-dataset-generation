
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_net_paid) AS total_net_paid,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name
),
TopIncomeCustomers AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating
    FROM customer_demographics cd
    WHERE cd.cd_purchase_estimate > (
        SELECT AVG(cd2.cd_purchase_estimate) 
        FROM customer_demographics cd2
    )
),
HighValueReturns AS (
    SELECT 
        sr_returning_customer_sk,
        SUM(sr_return_amt_inc_tax) AS total_return_amt
    FROM store_returns 
    WHERE sr_return_quantity > 0
    GROUP BY sr_returning_customer_sk
),
FinalAnalysis AS (
    SELECT 
        cs.c_customer_sk,
        cs.c_first_name,
        cs.c_last_name,
        cs.total_net_paid,
        COALESCE(hvr.total_return_amt, 0) AS total_return_amt,
        (CASE 
            WHEN cs.total_net_paid > 1000 THEN 'High Value'
            ELSE 'Low Value'
        END) AS customer_value_category
    FROM CustomerSales cs
    LEFT JOIN HighValueReturns hvr ON cs.c_customer_sk = hvr.sr_returning_customer_sk
    WHERE cs.c_customer_sk IN (
        SELECT c.c_customer_sk
        FROM customer c 
        INNER JOIN TopIncomeCustomers tic ON c.c_current_cdemo_sk = tic.cd_demo_sk
    )
)
SELECT 
    fa.c_customer_sk,
    fa.c_first_name,
    fa.c_last_name,
    fa.total_net_paid,
    fa.total_return_amt,
    fa.customer_value_category
FROM FinalAnalysis fa
ORDER BY fa.total_net_paid DESC, fa.total_return_amt ASC;
