
WITH HighValueCustomers AS (
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_credit_rating, cd.cd_purchase_estimate
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE cd.cd_purchase_estimate > 10000
), CustomerReturns AS (
    SELECT sr.returned_date_sk, sr.return_time_sk, sr_item_sk, sr_customer_sk, COUNT(*) AS total_returns
    FROM store_returns sr
    GROUP BY sr.returned_date_sk, sr.return_time_sk, sr_item_sk, sr_customer_sk
), ReturnsWithDetails AS (
    SELECT cr.*, i.i_item_desc, i.i_current_price
    FROM CustomerReturns cr
    JOIN item i ON cr.sr_item_sk = i.i_item_sk
), SalesAnalysis AS (
    SELECT ws.ws_bill_customer_sk, SUM(ws.ws_net_profit) AS total_profit, COUNT(ws.ws_order_number) AS total_sales
    FROM web_sales ws
    GROUP BY ws.ws_bill_customer_sk
), FinalReport AS (
    SELECT hvc.c_customer_sk, hvc.c_first_name, hvc.c_last_name, hvc.cd_credit_rating,
           COALESCE(SA.total_sales, 0) AS total_sales, COALESCE(SA.total_profit, 0) AS total_profit,
           COALESCE(SR.total_returns, 0) AS total_returns
    FROM HighValueCustomers hvc
    LEFT JOIN SalesAnalysis SA ON hvc.c_customer_sk = SA.ws_bill_customer_sk
    LEFT JOIN (
        SELECT sr_customer_sk, SUM(total_returns) AS total_returns
        FROM CustomerReturns
        GROUP BY sr_customer_sk
    ) SR ON hvc.c_customer_sk = SR.sr_customer_sk
)
SELECT f.c_customer_sk, f.c_first_name, f.c_last_name, f.cd_credit_rating, 
       f.total_sales, f.total_profit, f.total_returns 
FROM FinalReport f
ORDER BY f.total_profit DESC, f.total_sales DESC;
