
WITH RankedReturns AS (
    SELECT 
        wr_returning_customer_sk,
        COUNT(*) AS total_returns,
        SUM(wr_return_amt) AS total_return_amt,
        ROW_NUMBER() OVER (PARTITION BY wr_returning_customer_sk ORDER BY SUM(wr_return_amt) DESC) AS rn
    FROM web_returns
    GROUP BY wr_returning_customer_sk
),
TopReturningCustomers AS (
    SELECT wr_returning_customer_sk, total_returns, total_return_amt
    FROM RankedReturns
    WHERE rn <= 10
),
CustomerDetails AS (
    SELECT 
        c.c_customer_id, 
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        CASE 
            WHEN cd.cd_marital_status = 'M' THEN 'Married'
            WHEN cd.cd_marital_status = 'S' THEN 'Single'
            ELSE 'Other'
        END AS marital_status,
        ca.ca_city,
        ca.ca_state,
        COALESCE(NULLIF(c.c_email_address, ''), 'Email Not Provided') AS email
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
WebReturnSummary AS (
    SELECT 
        trc.wr_returning_customer_sk,
        cd.c_customer_id,
        cd.marital_status,
        cd.ca_city,
        cd.ca_state,
        SUM(CASE WHEN wr_return_quantity > 0 THEN wr_return_quantity ELSE 0 END) AS total_return_qty,
        COUNT(DISTINCT wr_order_number) AS distinct_orders,
        ROUND(SUM(wr_return_amt), 2) AS total_returned_amt
    FROM TopReturningCustomers trc
    JOIN web_returns wr ON trc.wr_returning_customer_sk = wr.wr_returning_customer_sk
    JOIN CustomerDetails cd ON wr.wr_returning_customer_sk = cd.c_customer_id
    GROUP BY trc.wr_returning_customer_sk, cd.c_customer_id, cd.marital_status, cd.ca_city, cd.ca_state
)
SELECT 
    wrc.wr_returning_customer_sk,
    wrc.total_return_qty,
    wrc.distinct_orders,
    wrc.total_returned_amt,
    cd.c_customer_id,
    cd.marital_status,
    cd.ca_city,
    cd.ca_state
FROM WebReturnSummary wrc
JOIN CustomerDetails cd ON wrc.c_customer_id = cd.c_customer_id
WHERE wrc.total_returned_amt > (
        SELECT AVG(total_return_amt)
        FROM WebReturnSummary
    )
ORDER BY wrc.total_returned_amt DESC
LIMIT 100;
