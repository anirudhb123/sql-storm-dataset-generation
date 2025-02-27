
WITH RankedCustomers AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS rank
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
TopCustomers AS (
    SELECT 
        rc.c_customer_id,
        rc.c_first_name,
        rc.c_last_name,
        rc.cd_gender,
        rc.cd_marital_status,
        rc.cd_purchase_estimate
    FROM RankedCustomers rc
    WHERE rc.rank <= 5
),
CustomerReturns AS (
    SELECT 
        sr_returning_customer_sk, 
        SUM(sr_return_amt) AS total_return_amt,
        COUNT(DISTINCT sr_ticket_number) AS return_count
    FROM store_returns
    GROUP BY sr_returning_customer_sk
),
CustomerSales AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_sales_price) AS total_sales_amt,
        COUNT(DISTINCT ws_order_number) AS sales_count
    FROM web_sales
    WHERE ws_ship_date_sk IS NOT NULL
    GROUP BY ws_bill_customer_sk
)
SELECT 
    tc.c_customer_id,
    tc.c_first_name,
    tc.c_last_name,
    tc.cd_gender,
    tc.cd_marital_status,
    COALESCE(cr.total_return_amt, 0) AS total_return_amt,
    COALESCE(cs.total_sales_amt, 0) AS total_sales_amt,
    COALESCE(cr.return_count, 0) AS return_count,
    COALESCE(cs.sales_count, 0) AS sales_count,
    CASE 
        WHEN COALESCE(cs.total_sales_amt, 0) > 0 THEN 
            (COALESCE(cr.total_return_amt, 0) / COALESCE(cs.total_sales_amt, 0)) * 100
        ELSE 0 END AS return_ratio
FROM TopCustomers tc
LEFT JOIN CustomerReturns cr ON tc.c_customer_id = cr.sr_returning_customer_sk
LEFT JOIN CustomerSales cs ON tc.c_customer_id = cs.ws_bill_customer_sk
ORDER BY return_ratio DESC;
