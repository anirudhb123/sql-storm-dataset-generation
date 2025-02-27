
WITH RecursiveCustomerData AS (
    SELECT c.c_customer_sk,
           c.c_first_name,
           c.c_last_name,
           c.c_preferred_cust_flag,
           cd.cd_gender,
           cd.cd_marital_status,
           cd.cd_purchase_estimate,
           cd.cd_credit_rating,
           ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS purchase_rank
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE c.c_first_shipto_date_sk IS NOT NULL
),
HighValueCustomer AS (
    SELECT DISTINCT c_customer_sk, c_first_name, c_last_name
    FROM RecursiveCustomerData
    WHERE purchase_rank <= 10
),
ReturningCustomers AS (
    SELECT DISTINCT sr_customer_sk,
           COUNT(DISTINCT sr_item_sk) AS total_returns,
           SUM(sr_return_amt) AS total_returned_amount
    FROM store_returns
    WHERE sr_returned_date_sk > (
        SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY sr_customer_sk
),
FinalReport AS (
    SELECT r.c_customer_sk,
           r.c_first_name,
           r.c_last_name,
           r.total_returns,
           r.total_returned_amount,
           CASE
               WHEN r.total_returned_amount IS NULL THEN 'No Returns'
               ELSE CASE 
                   WHEN r.total_returned_amount > 500 THEN 'High Returner'
                   ELSE 'Regular Returner'
               END
           END AS return_status
    FROM ReturningCustomers r
    INNER JOIN HighValueCustomer hv ON r.sr_customer_sk = hv.c_customer_sk
)
SELECT f.c_first_name,
       f.c_last_name,
       f.total_returns,
       f.total_returned_amount,
       f.return_status,
       w.w_warehouse_name,
       SUM(ws.ws_net_profit) OVER (PARTITION BY f.c_customer_sk) AS total_profit_from_sales,
       COALESCE((SELECT COUNT(*) 
                  FROM web_sales 
                  WHERE ws_bill_customer_sk = f.c_customer_sk 
                    AND ws_sold_date_sk > (
                        SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)), 0) AS recent_web_sales
FROM FinalReport f
LEFT JOIN warehouse w ON w.w_warehouse_sk IN (
    SELECT inv.inv_warehouse_sk 
    FROM inventory inv 
    WHERE inv.inv_quantity_on_hand > 10 
    GROUP BY inv.inv_warehouse_sk 
    HAVING SUM(inv.inv_quantity_on_hand) > 100)
ORDER BY f.total_returned_amount DESC, f.c_last_name ASC;
