
WITH CustomerReturns AS (
    SELECT 
        cr_returning_customer_sk,
        COUNT(DISTINCT cr_order_number) AS return_count,
        SUM(cr_return_amt_inc_tax) AS total_return_amt,
        SUM(cr_return_quantity) AS total_return_quantity
    FROM catalog_returns
    WHERE cr_return_quantity > 0
    GROUP BY cr_returning_customer_sk
),
WebSalesWithReturns AS (
    SELECT 
        ws.ws_customer_sk,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        SUM(COALESCE(cr.total_return_amt, 0)) AS total_returns,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        COUNT(DISTINCT cr.return_count) AS return_count
    FROM web_sales ws
    LEFT JOIN CustomerReturns cr ON ws.ws_customer_sk = cr.cr_returning_customer_sk
    GROUP BY ws.ws_customer_sk
),
QualifiedCustomers AS (
    SELECT 
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        w.w_warehouse_id,
        COALESCE(s.total_sales, 0) AS total_sales,
        COALESCE(s.total_returns, 0) AS total_returns,
        (COALESCE(s.total_sales, 0) - COALESCE(s.total_returns, 0)) AS net_revenue,
        LEAD(net_revenue) OVER (PARTITION BY cd.cd_gender ORDER BY net_revenue DESC) AS next_net_revenue,
        CASE 
            WHEN cd.cd_marital_status = 'S' AND (coalesce(cd.cd_dep_count, 0) > 0 OR coalesce(cd.cd_dep_college_count, 0) > 0) THEN 'Single with dependents'
            WHEN cd.cd_marital_status = 'M' THEN 'Married'
            ELSE 'Other'
        END AS marital_dependent_category
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN WebSalesWithReturns s ON c.c_customer_sk = s.ws_customer_sk
    LEFT JOIN warehouse w ON w.w_warehouse_sk = (SELECT TOP 1 w_warehouse_sk FROM warehouse ORDER BY w_warehouse_sq_ft DESC)
    WHERE cd.cd_purchase_estimate > 1000
),
FinalResults AS (
    SELECT 
        qc.c_customer_id,
        qc.cd_gender,
        qc.marital_dependent_category,
        qc.w_warehouse_id,
        qc.total_sales,
        qc.total_returns,
        qc.net_revenue,
        CASE 
            WHEN qc.next_net_revenue IS NULL THEN 'No Next Revenue'
            WHEN qc.net_revenue > qc.next_net_revenue THEN 'Increasing Revenue'
            ELSE 'Decreasing Revenue' 
        END AS revenue_trend
    FROM QualifiedCustomers qc
    HAVING COUNT(qc.c_customer_id) > 1
)
SELECT 
    fr.c_customer_id,
    fr.cd_gender,
    fr.marital_dependent_category,
    fr.w_warehouse_id,
    fr.total_sales,
    fr.total_returns,
    fr.net_revenue,
    fr.revenue_trend
FROM FinalResults fr
WHERE fr.marital_dependent_category IS NOT NULL
ORDER BY fr.net_revenue DESC;
