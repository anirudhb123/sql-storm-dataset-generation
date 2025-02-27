
WITH RankedCustomers AS (
    SELECT 
        c.c_customer_sk,
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_income_band_sk,
        COUNT(ss.ss_ticket_number) AS total_purchases,
        SUM(ss.ss_net_profit) AS total_net_profit,
        RANK() OVER (PARTITION BY cd.cd_income_band_sk ORDER BY SUM(ss.ss_net_profit) DESC) AS income_rank
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_customer_id, cd.cd_gender, cd.cd_marital_status, cd.cd_income_band_sk
),
TopIncomeCustomers AS (
    SELECT 
        c.customer_id,
        c.total_purchases,
        c.total_net_profit,
        c.income_rank
    FROM 
        RankedCustomers c
    WHERE 
        c.income_rank = 1
),
SalesSummary AS (
    SELECT 
        w.w_warehouse_id,
        SUM(ws.ws_quantity) AS total_web_sales,
        SUM(ws.ws_net_profit) AS total_web_profit
    FROM 
        web_sales ws
    JOIN 
        warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    GROUP BY 
        w.w_warehouse_id
)
SELECT 
    ic.customer_id,
    ic.total_purchases,
    ic.total_net_profit,
    ss.total_web_sales,
    ss.total_web_profit,
    COALESCE(ss.total_web_sales, 0) - COALESCE(ic.total_net_profit, 0) AS profit_deficit
FROM 
    TopIncomeCustomers ic
FULL OUTER JOIN 
    SalesSummary ss ON ic.income_rank = 1
WHERE 
    COALESCE(ss.total_web_profit, 0) > 1000
ORDER BY 
    profit_deficit DESC;
