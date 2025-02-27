
WITH RankedReturns AS (
    SELECT 
        sr.customer_sk,
        SUM(sr.return_quantity) AS total_return_quantity,
        SUM(sr.return_amt) AS total_return_amt,
        RANK() OVER (PARTITION BY sr.customer_sk ORDER BY SUM(sr.return_quantity) DESC) AS return_rank
    FROM store_returns sr
    GROUP BY sr.customer_sk
),
CustomerInfo AS (
    SELECT 
        c.customer_sk,
        c.first_name,
        c.last_name,
        cd.gender,
        cd.marital_status,
        cd.education_status,
        COALESCE(cd.purchase_estimate, 0) AS purchase_estimate
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.current_cdemo_sk = cd.demo_sk
),
TopReturningCustomers AS (
    SELECT 
        ci.customer_sk,
        ci.first_name,
        ci.last_name,
        ci.gender,
        ci.marital_status,
        ci.education_status,
        ci.purchase_estimate,
        rr.total_return_quantity,
        rr.total_return_amt
    FROM RankedReturns rr
    JOIN CustomerInfo ci ON rr.customer_sk = ci.customer_sk
    WHERE rr.return_rank <= 10
),
AverageReturnedItemInfo AS (
    SELECT 
        ir.item_sk,
        AVG(ir.return_quantity) AS avg_return_quantity,
        AVG(ir.return_amt) AS avg_return_amt
    FROM (
        SELECT sr_items.item_sk, sr_items.return_quantity, sr_items.return_amt 
        FROM (
            SELECT
                sr_item_sk AS item_sk,
                SUM(sr_return_quantity) AS return_quantity,
                SUM(sr_return_amt) AS return_amt
            FROM store_returns
            GROUP BY sr_item_sk
        ) sr_items
    ) ir
    GROUP BY ir.item_sk
)
SELECT 
    trc.first_name,
    trc.last_name,
    trc.gender,
    trc.marital_status,
    trc.education_status,
    trc.purchase_estimate,
    trc.total_return_quantity,
    trc.total_return_amt,
    ai.avg_return_quantity,
    ai.avg_return_amt
FROM TopReturningCustomers trc
LEFT JOIN AverageReturnedItemInfo ai ON ai.item_sk IN (
    SELECT sr_item_sk FROM store_returns WHERE sr_customer_sk = trc.customer_sk
)
ORDER BY trc.total_return_amt DESC, trc.total_return_quantity DESC;
