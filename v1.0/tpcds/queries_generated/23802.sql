
WITH RankedReturns AS (
    SELECT 
        sr_returning_customer_sk,
        SUM(sr_return_quantity) AS total_returned,
        DENSE_RANK() OVER (PARTITION BY sr_returning_customer_sk ORDER BY SUM(sr_return_quantity) DESC) AS return_rank
    FROM 
        store_returns
    GROUP BY 
        sr_returning_customer_sk
),
CustomerSales AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_net_paid_inc_tax) AS total_spent,
        COUNT(DISTINCT ws_order_number) AS order_count,
        MAX(ws_ship_date_sk) AS last_purchase_date
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
),
HighValueCustomers AS (
    SELECT 
        cs.ws_bill_customer_sk,
        cs.total_spent,
        cs.order_count,
        cr.total_returned,
        (cs.total_spent - COALESCE(cr.total_returned, 0)) AS net_spent
    FROM 
        CustomerSales cs
    LEFT JOIN 
        RankedReturns cr ON cs.ws_bill_customer_sk = cr.sr_returning_customer_sk AND cr.return_rank = 1
    WHERE 
        cs.total_spent > (SELECT AVG(total_spent) FROM CustomerSales)
),
DatedReturns AS (
    SELECT 
        wr_returned_date_sk,
        wr_returning_customer_sk,
        COUNT(*) AS return_count
    FROM 
        web_returns
    GROUP BY 
        wr_returned_date_sk, wr_returning_customer_sk
),
FinalAnalysis AS (
    SELECT 
        hvc.ws_bill_customer_sk,
        hvc.total_spent,
        hvc.order_count,
        COALESCE(dr.return_count, 0) AS return_count,
        DATEDIFF(CURRENT_DATE, MAX(hvc.last_purchase_date)) AS days_since_last_purchase
    FROM 
        HighValueCustomers hvc
    LEFT JOIN 
        DatedReturns dr ON hvc.ws_bill_customer_sk = dr.wr_returning_customer_sk
    GROUP BY 
        hvc.ws_bill_customer_sk, hvc.total_spent, hvc.order_count
)
SELECT 
    fa.ws_bill_customer_sk,
    fa.total_spent,
    fa.order_count,
    fa.return_count,
    fa.days_since_last_purchase,
    CASE 
        WHEN fa.days_since_last_purchase > 365 THEN 'Inactive'
        WHEN fa.days_since_last_purchase BETWEEN 180 AND 365 THEN 'At Risk'
        ELSE 'Active'
    END AS customer_status
FROM 
    FinalAnalysis fa
ORDER BY 
    fa.total_spent DESC, fa.return_count ASC;
