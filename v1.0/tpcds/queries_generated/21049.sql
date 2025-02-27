
WITH RankedCustomers AS (
    SELECT 
        c.c_customer_sk,
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        RANK() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS gender_rank
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE cd.cd_purchase_estimate IS NOT NULL
),
RecentReturns AS (
    SELECT 
        sr_returned_date_sk,
        COUNT(sr_item_sk) AS total_returns,
        SUM(sr_return_amt) AS total_return_amt
    FROM store_returns
    WHERE sr_returned_date_sk >= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY sr_returned_date_sk
),
SalesSummary AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_net_paid) AS total_sales,
        COUNT(ws_order_number) AS order_count
    FROM web_sales
    WHERE ws_sold_date_sk > (SELECT MIN(d_date_sk) FROM date_dim WHERE d_month_seq = (SELECT MAX(d_month_seq) FROM date_dim WHERE d_year = 2023))
    GROUP BY ws_bill_customer_sk
)
SELECT 
    rc.c_customer_id,
    rc.cd_gender,
    rc.cd_marital_status,
    COALESCE(ss.total_sales, 0) AS customer_total_sales,
    COALESCE(rr.total_return_amt, 0) AS return_amount,
    CASE 
        WHEN rc.gender_rank IS NOT NULL THEN rc.gender_rank 
        ELSE 99999 
    END AS ranking,
    CASE 
        WHEN ss.order_count > 0 THEN 'Active'
        WHEN rr.total_returns IS NOT NULL AND rr.total_returns > 0 THEN 'Inactive'
        ELSE 'Unknown'
    END AS customer_status
FROM RankedCustomers rc
LEFT JOIN SalesSummary ss ON rc.c_customer_sk = ss.ws_bill_customer_sk
LEFT JOIN RecentReturns rr ON rr.sr_returned_date_sk = (SELECT MAX(sr_returned_date_sk) FROM store_returns WHERE sr_returning_customer_sk = rc.c_customer_sk)
WHERE rc.gender_rank <= 5
ORDER BY rc.cd_gender, customer_total_sales DESC, rr.total_return_amt ASC;
