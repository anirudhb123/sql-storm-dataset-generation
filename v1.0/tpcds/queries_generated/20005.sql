
WITH RankedCustomers AS (
    SELECT 
        c.c_customer_id, 
        c.c_first_name, 
        c.c_last_name, 
        cd.cd_gender, 
        cd.cd_marital_status,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY c.c_last_name) AS rn
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        cd.cd_purchase_estimate IS NOT NULL
    AND 
        cd.cd_credit_rating IN ('Fair', 'Good')
),
SalesData AS (
    SELECT 
        ws_bill_customer_sk, 
        SUM(ws_net_profit) AS total_profit,
        COUNT(ws_order_number) AS total_orders,
        DENSE_RANK() OVER (PARTITION BY ws_bill_customer_sk ORDER BY SUM(ws_net_profit) DESC) AS profit_rank
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
),
RecentReturns AS (
    SELECT 
        sr_customer_sk, 
        SUM(sr_return_amt) AS total_return_amt,
        COUNT(sr_ticket_number) AS total_returns,
        MAX(sr_returned_date_sk) AS last_return_date
    FROM 
        store_returns
    WHERE 
        sr_return_time_sk IS NOT NULL
    GROUP BY 
        sr_customer_sk
)
SELECT 
    rc.c_customer_id,
    rc.c_first_name,
    rc.c_last_name,
    sd.total_profit,
    sd.total_orders,
    COALESCE(rr.total_return_amt, 0) AS total_return_amt,
    COALESCE(rr.total_returns, 0) AS total_returns,
    (CASE 
        WHEN rr.total_return_amt IS NOT NULL THEN 'Potential Issue' 
        ELSE 'Clean Account' 
    END) AS account_status,
    (DATE(d.d_date) - INTERVAL '3 month') AS last_purchase,
    (CASE 
        WHEN rc.rn = 1 THEN 'First' 
        WHEN rc.rn BETWEEN 2 AND 5 THEN 'Top 5' 
        ELSE 'Others' 
    END) AS customer_rank
FROM 
    RankedCustomers rc
LEFT JOIN 
    SalesData sd ON rc.c_customer_id = sd.ws_bill_customer_sk
LEFT JOIN 
    RecentReturns rr ON rc.c_customer_id = rr.sr_customer_sk
JOIN 
    date_dim d ON d.d_date_sk = COALESCE(rr.last_return_date, 0)
WHERE 
    rc.rn <= 10
AND 
    (sd.total_profit IS NOT NULL OR rr.total_return_amt IS NOT NULL)
ORDER BY 
    rc.c_last_name ASC, sd.total_profit DESC
LIMIT 25;
