
WITH CustomerReturns AS (
    SELECT
        wr_returning_customer_sk,
        SUM(wr_return_quantity) AS total_return_quantity,
        SUM(wr_return_amt) AS total_return_amount,
        COUNT(DISTINCT wr_return_number) AS return_count
    FROM web_returns
    GROUP BY wr_returning_customer_sk
),
TopCustomers AS (
    SELECT
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_credit_rating,
        COALESCE(cr.total_return_quantity, 0) AS total_return_quantity,
        COALESCE(cr.total_return_amount, 0) AS total_return_amount,
        RANK() OVER (ORDER BY COALESCE(cr.total_return_amount, 0) DESC) AS rank
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN CustomerReturns cr ON c.c_customer_sk = cr.wr_returning_customer_sk
    WHERE cd.cd_gender IS NOT NULL 
      AND cd.cd_credit_rating IS NOT NULL
),
SalesSummary AS (
    SELECT
        ws_bill_customer_sk,
        SUM(ws_net_profit) AS total_profit,
        COUNT(DISTINCT ws_order_number) AS order_count,
        SUM(ws_quantity) AS total_quantity
    FROM web_sales
    GROUP BY ws_bill_customer_sk
)
SELECT
    tc.c_customer_id,
    tc.cd_gender,
    tc.cd_marital_status,
    tc.cd_credit_rating,
    tc.total_return_quantity,
    tc.total_return_amount,
    COALESCE(ss.total_profit, 0) AS total_profit,
    COALESCE(ss.order_count, 0) AS order_count,
    COALESCE(ss.total_quantity, 0) AS total_quantity
FROM TopCustomers tc
LEFT JOIN SalesSummary ss ON tc.c_customer_id = ss.ws_bill_customer_sk
WHERE tc.rank <= 10
ORDER BY tc.total_return_amount DESC
