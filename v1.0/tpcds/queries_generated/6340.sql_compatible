
WITH CustomerReturns AS (
    SELECT 
        sr_customer_sk,
        COUNT(sr_item_sk) AS total_returns,
        SUM(sr_return_amt_inc_tax) AS total_return_amount,
        AVG(sr_return_quantity) AS avg_return_quantity
    FROM store_returns
    WHERE sr_returned_date_sk BETWEEN (SELECT d_date_sk FROM date_dim WHERE d_date = '2023-01-01')
        AND (SELECT d_date_sk FROM date_dim WHERE d_date = '2023-12-31')
    GROUP BY sr_customer_sk
),
HighValueCustomers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        cr.total_returns,
        cr.total_return_amount,
        cr.avg_return_quantity
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN CustomerReturns cr ON c.c_customer_sk = cr.sr_customer_sk
    WHERE cr.total_return_amount > (SELECT AVG(total_return_amount) FROM CustomerReturns)
),
StoreInfo AS (
    SELECT 
        s.s_store_sk,
        s.s_store_name,
        SUM(ss.net_paid) AS total_sales,
        COUNT(DISTINCT ss.ticket_number) AS total_transactions
    FROM store s
    JOIN store_sales ss ON s.s_store_sk = ss.ss_store_sk
    WHERE ss.ss_sold_date_sk BETWEEN (SELECT d_date_sk FROM date_dim WHERE d_date = '2023-01-01')
        AND (SELECT d_date_sk FROM date_dim WHERE d_date = '2023-12-31')
    GROUP BY s.s_store_sk, s.s_store_name
)
SELECT 
    hvc.c_first_name,
    hvc.c_last_name,
    hvc.cd_gender,
    hvc.cd_marital_status,
    si.s_store_name,
    si.total_sales,
    si.total_transactions,
    hvc.total_return_amount,
    hvc.avg_return_quantity
FROM HighValueCustomers hvc
JOIN StoreInfo si ON si.total_sales > (SELECT AVG(total_sales) FROM StoreInfo)
ORDER BY hvc.total_return_amount DESC, si.total_sales DESC;
