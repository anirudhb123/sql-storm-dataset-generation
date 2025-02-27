
WITH RankedSales AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_net_profit) AS total_profit,
        RANK() OVER (PARTITION BY ws_bill_customer_sk ORDER BY SUM(ws_net_profit) DESC) AS profit_rank
    FROM 
        web_sales
    WHERE 
        ws_net_profit IS NOT NULL
    GROUP BY 
        ws_bill_customer_sk
),
CustomerDemo AS (
    SELECT 
        c.c_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        COALESCE(SUM(ws_net_profit), 0) AS total_net_profit
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, cd.cd_gender, cd.cd_marital_status, cd.cd_purchase_estimate
),
CustomerRanking AS (
    SELECT 
        cd.c_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        cd.total_net_profit,
        RANK() OVER (ORDER BY cd.total_net_profit DESC) AS customer_rank,
        CASE 
            WHEN cd.cd_purchase_estimate IS NULL THEN 'NO ESTIMATE'
            WHEN cd.total_net_profit = 0 THEN 'NO SALES'
            ELSE 'ACTIVE CUSTOMER'
        END AS customer_status
    FROM 
        CustomerDemo cd
),
ReturnAnalytics AS (
    SELECT 
        sr_customer_sk,
        COUNT(sr_ticket_number) AS total_returns,
        SUM(sr_return_amt) AS total_return_amount,
        AVG(sr_return_quantity) AS avg_return_quantity,
        CASE 
            WHEN SUM(sr_return_amt) IS NULL THEN 'UNKNOWN RETURN VALUE'
            WHEN SUM(sr_return_amt) > 0 THEN 'RETURNED FUNDS RECEIVED'
            ELSE 'NO RETURNS'
        END AS return_status
    FROM 
        store_returns
    GROUP BY 
        sr_customer_sk
),
FinalReport AS (
    SELECT 
        cr.customer_rank,
        cr.cd_gender,
        cr.cd_marital_status,
        cr.cd_purchase_estimate,
        ra.total_returns,
        ra.total_return_amount,
        ra.avg_return_quantity,
        ra.return_status,
        CASE 
            WHEN cr.customer_rank <= 10 THEN 'TOP CUSTOMER'
            ELSE 'REGULAR CUSTOMER'
        END AS customer_category
    FROM 
        CustomerRanking cr
    LEFT JOIN 
        ReturnAnalytics ra ON cr.c_customer_sk = ra.sr_customer_sk
)
SELECT 
    f.customer_rank,
    f.cd_gender,
    f.cd_marital_status,
    f.customer_category,
    COALESCE(f.total_returns, 0) AS total_returns,
    COALESCE(f.total_return_amount, 0.00) AS total_return_amount,
    f.avg_return_quantity,
    f.return_status
FROM 
    FinalReport f
WHERE 
    f.customer_status = 'ACTIVE CUSTOMER'
ORDER BY 
    f.total_return_amount DESC, 
    f.average_return_quantity DESC
LIMIT 50;
