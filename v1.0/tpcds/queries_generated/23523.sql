
WITH active_customers AS (
    SELECT 
        c_customer_sk, 
        c_first_name, 
        c_last_name, 
        cd_gender,
        cd_margin_status,
        cd_credit_rating,
        ROW_NUMBER() OVER (PARTITION BY cd_gender ORDER BY c_customer_sk) AS rn
    FROM 
        customer 
    JOIN 
        customer_demographics ON c_current_cdemo_sk = cd_demo_sk
    WHERE 
        cd_credit_rating IN ('Excellent', 'Good')
),
total_sales AS (
    SELECT 
        ws_bill_customer_sk, 
        SUM(ws_net_paid) AS total_net_paid
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
),
return_metrics AS (
    SELECT 
        sr_customer_sk,
        COUNT(DISTINCT sr_ticket_number) AS total_returns,
        SUM(sr_return_amt) AS total_return_amt
    FROM 
        store_returns
    GROUP BY 
        sr_customer_sk
),
combined_metrics AS (
    SELECT 
        ac.c_customer_sk,
        ac.c_first_name,
        ac.c_last_name,
        ts.total_net_paid,
        COALESCE(rm.total_returns, 0) AS total_returns,
        COALESCE(rm.total_return_amt, 0) AS total_return_amt,
        CASE
            WHEN COALESCE(rm.total_returns, 0) > 0 THEN 'High Return Customer'
            WHEN ts.total_net_paid > 1000 THEN 'High Value Customer'
            ELSE 'Regular Customer'
        END AS customer_type
    FROM 
        active_customers ac
    LEFT JOIN 
        total_sales ts ON ac.c_customer_sk = ts.ws_bill_customer_sk
    LEFT JOIN 
        return_metrics rm ON ac.c_customer_sk = rm.sr_customer_sk
)
SELECT 
    cm.c_customer_sk,
    cm.c_first_name,
    cm.c_last_name,
    cm.total_net_paid,
    cm.total_returns,
    cm.total_return_amt,
    cm.customer_type
FROM 
    combined_metrics cm
WHERE 
    cm.customer_type = 'High Return Customer'
    OR (cm.total_net_paid IS NULL AND (cm.total_returns > 5 OR cm.total_return_amt > 100))
ORDER BY 
    cm.total_net_paid DESC NULLS LAST
FETCH FIRST 10 ROWS ONLY;
