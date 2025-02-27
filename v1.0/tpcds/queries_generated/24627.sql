
WITH CustomerReturnStats AS (
    SELECT 
        c.c_customer_sk,
        COUNT(DISTINCT sr_ticket_number) AS total_returns,
        SUM(sr_return_amt) AS total_return_amount,
        AVG(sr_return_quantity) AS avg_return_quantity,
        SUM(sr_return_amt_inc_tax) - SUM(sr_discount) AS net_return_amount
    FROM 
        customer c
    LEFT JOIN 
        store_returns sr ON c.c_customer_sk = sr.sr_customer_sk
    GROUP BY 
        c.c_customer_sk
),
HighValueCustomers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        cs.total_returns,
        cs.total_return_amount,
        RANK() OVER (PARTITION BY cd.cd_gender ORDER BY cs.total_return_amount DESC) AS gender_rank
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        CustomerReturnStats cs ON c.c_customer_sk = cs.c_customer_sk
    WHERE 
        cd.cd_purchase_estimate > 1000
    HAVING 
        COUNT(cs.total_returns) > 5
),
ReturnReasons AS (
    SELECT 
        sr_reason_sk,
        COUNT(*) AS reason_count,
        AVG(sr_return_amt_inc_tax) AS avg_return_value
    FROM 
        store_returns 
    GROUP BY 
        sr_reason_sk
    HAVING 
        reason_count > 10
)
SELECT 
    hvc.c_first_name,
    hvc.c_last_name,
    hvc.cd_gender,
    hvc.cd_marital_status,
    COALESCE(rr.reason_count, 0) AS return_reason_count,
    COALESCE(rr.avg_return_value, 0) AS average_return_value,
    CASE 
        WHEN rr.reason_count IS NOT NULL THEN 'Regular Return'
        ELSE 'No Returns Found'
    END AS return_summary,
    ROW_NUMBER() OVER (PARTITION BY hvc.cd_gender ORDER BY hvc.total_return_amount DESC) AS row_num
FROM 
    HighValueCustomers hvc
LEFT JOIN 
    ReturnReasons rr ON hvc.c_customer_sk = rr.sr_reason_sk
WHERE 
    hvc.gender_rank <= 10
ORDER BY 
    hvc.cd_gender, hvc.total_return_amount DESC;
