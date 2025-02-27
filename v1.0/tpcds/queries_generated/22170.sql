
WITH CustomerReturns AS (
    SELECT 
        sr_return_customer_sk,
        SUM(sr_return_quantity) AS total_returned_quantity,
        COUNT(DISTINCT sr_ticket_number) AS total_returns,
        SUM(sr_return_amt) AS total_returned_amount
    FROM store_returns
    GROUP BY sr_return_customer_sk
),
CustomerDemographics AS (
    SELECT 
        c.c_customer_id,
        d.cd_gender,
        d.cd_marital_status,
        d.cd_purchase_estimate,
        d.cd_credit_rating,
        d.cd_dep_count
    FROM customer c
    JOIN customer_demographics d ON c.c_current_cdemo_sk = d.cd_demo_sk
),
WarehouseReturns AS (
    SELECT 
        w.w_warehouse_id,
        SUM(CASE WHEN r.r_reason_desc IS NULL THEN 0 ELSE 1 END) AS null_reason_count,
        SUM(CASE WHEN r.r_reason_desc IS NOT NULL THEN 1 ELSE 0 END) AS non_null_reason_count
    FROM warehouse w
    LEFT JOIN store_returns sr ON sr.sr_store_sk = w.w_warehouse_sk
    LEFT JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    GROUP BY w.w_warehouse_id
),
MonthlySales AS (
    SELECT 
        d.d_year,
        d.d_month_seq,
        SUM(ws_net_paid) AS total_sales,
        COUNT(*) AS sales_count
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    GROUP BY d.d_year, d.d_month_seq
),
TopCustomers AS (
    SELECT 
        d.c_customer_id,
        SUM(ws_net_paid) AS total_spent
    FROM web_sales ws
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN CustomerDemographics d ON c.c_current_cdemo_sk = d.cd_demo_sk
    GROUP BY d.c_customer_id
    HAVING SUM(ws_net_paid) > (SELECT AVG(total_spent) FROM TopCustomers)
),
FinalReport AS (
    SELECT 
        cd.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        cr.total_returned_quantity,
        cr.total_returns,
        cr.total_returned_amount,
        wr.null_reason_count,
        wr.non_null_reason_count,
        ms.total_sales,
        ms.sales_count
    FROM CustomerDemographics cd
    LEFT JOIN CustomerReturns cr ON cd.c_customer_id = cr.sr_return_customer_sk
    LEFT JOIN WarehouseReturns wr ON wr.w_warehouse_id = (SELECT w.w_warehouse_id FROM warehouse w WHERE w.w_warehouse_sk = (SELECT MIN(w.w_warehouse_sk) FROM warehouse))
    JOIN MonthlySales ms ON ms.d_year = EXTRACT(YEAR FROM CURRENT_DATE)
    WHERE cd.cd_purchase_estimate IS NOT NULL
    OR (cd.cd_dep_count IS NULL AND cd.cd_marital_status = 'M')
)
SELECT 
    f.c_customer_id,
    f.cd_gender,
    f.cd_marital_status,
    f.total_returned_quantity,
    f.total_returns,
    f.total_returned_amount,
    f.null_reason_count,
    f.non_null_reason_count,
    f.total_sales
FROM FinalReport f
ORDER BY f.total_returned_amount DESC NULLS LAST
FETCH FIRST 100 ROWS ONLY;
