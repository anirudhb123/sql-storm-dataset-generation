
WITH RankedReturns AS (
    SELECT 
        sr_customer_sk,
        SUM(sr_return_amt_inc_tax) AS total_return_amt,
        COUNT(sr_return_quantity) AS total_returns,
        ROW_NUMBER() OVER (PARTITION BY sr_customer_sk ORDER BY SUM(sr_return_amt_inc_tax) DESC) AS rn
    FROM 
        store_returns
    GROUP BY 
        sr_customer_sk
),
HighValueCustomers AS (
    SELECT 
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        r.total_return_amt,
        r.total_returns
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        RankedReturns r ON c.c_customer_sk = r.sr_customer_sk
    WHERE 
        r.rn = 1 
        AND r.total_return_amt > (
            SELECT 
                AVG(total_return_amt) * 1.5 
            FROM 
                RankedReturns
        )
),
StoreInsights AS (
    SELECT 
        s.s_store_id,
        s.s_store_name,
        COUNT(CASE WHEN sr.total_return_amt IS NOT NULL THEN 1 END) AS total_returns,
        AVG(ws.ws_net_profit) AS avg_net_profit,
        (SELECT COUNT(*) FROM customer WHERE c_current_hdemo_sk IS NOT NULL) AS total_customers
    FROM 
        store s
    LEFT JOIN 
        store_returns sr ON s.s_store_sk = sr.s_store_sk
    LEFT JOIN 
        web_sales ws ON sr.sr_item_sk = ws.ws_item_sk AND sr.sr_ticket_number = ws.ws_order_number
    GROUP BY 
        s.s_store_id, s.s_store_name
)
SELECT 
    hvc.c_customer_id,
    hvc.cd_gender,
    hvc.cd_marital_status,
    si.s_store_id,
    si.s_store_name,
    si.total_returns,
    si.avg_net_profit,
    si.total_customers
FROM 
    HighValueCustomers hvc
JOIN 
    StoreInsights si ON hvc.total_returns > si.total_returns
ORDER BY 
    si.avg_net_profit DESC, hvc.total_return_amt DESC;
