
WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_net_profit,
        RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_net_profit DESC) AS profit_rank
    FROM 
        web_sales ws
    WHERE 
        ws.ws_net_profit IS NOT NULL
        AND ws.ws_quantity > 0
),
HighValueCustomers AS (
    SELECT 
        c.c_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        SUM(ws.ws_net_profit) AS total_spent
    FROM 
        customer c
        JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
        LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    WHERE 
        cd.cd_marital_status = 'M'
        AND cd.cd_gender = 'F'
        AND ws.ws_net_profit IS NOT NULL
    GROUP BY 
        c.c_customer_sk, cd.cd_gender, cd.cd_marital_status
    HAVING 
        SUM(ws.ws_net_profit) > 1000
),
RecentReturns AS (
    SELECT 
        sr_customer_sk,
        SUM(sr_return_amt) AS total_returned
    FROM 
        store_returns
    WHERE 
        sr_return_date_sk > (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023) - 30
    GROUP BY 
        sr_customer_sk
),
FinalReport AS (
    SELECT 
        hvc.c_customer_sk,
        hvc.total_spent,
        COALESCE(rr.total_returned, 0) AS total_returned,
        (hvc.total_spent - COALESCE(rr.total_returned, 0)) AS net_spent
    FROM 
        HighValueCustomers hvc
    LEFT JOIN RecentReturns rr ON hvc.c_customer_sk = rr.sr_customer_sk
)
SELECT 
    fr.c_customer_sk,
    fr.total_spent,
    fr.total_returned,
    fr.net_spent,
    CASE 
        WHEN fr.net_spent > 200 THEN 'High Value'
        WHEN fr.net_spent BETWEEN 100 AND 200 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS customer_value_segment
FROM 
    FinalReport fr
WHERE 
    fr.total_spent IS NOT NULL
    AND fr.total_returned IS NOT NULL
ORDER BY 
    fr.net_spent DESC, 
    fr.total_spent DESC;
