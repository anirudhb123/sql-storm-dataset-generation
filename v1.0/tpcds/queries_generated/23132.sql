
WITH RankedSales AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_item_sk,
        ws.ws_quantity,
        ws.ws_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_order_number ORDER BY ws.ws_net_profit DESC) AS rn
    FROM 
        web_sales ws
    WHERE 
        ws.ws_net_profit IS NOT NULL
),
TotalReturns AS (
    SELECT 
        cr.cr_item_sk,
        COUNT(*) AS total_returns,
        SUM(cr.cr_return_amount) AS total_return_amount
    FROM 
        catalog_returns cr
    GROUP BY 
        cr.cr_item_sk
),
CustomerInfo AS (
    SELECT 
        c.c_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_net_profit) AS total_spent
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk 
    GROUP BY 
        c.c_customer_sk, cd.cd_gender, cd.cd_marital_status
),
SalesSummary AS (
    SELECT 
        s_store_sk,
        SUM(ss_net_profit) AS total_store_profit
    FROM 
        store_sales
    GROUP BY 
        s_store_sk
)
SELECT 
    ci.c_customer_sk,
    ci.cd_gender,
    ci.cd_marital_status,
    COALESCE(rs.rn, 0) AS rank,
    COALESCE(tr.total_returns, 0) AS return_count,
    COALESCE(tr.total_return_amount, 0.00) AS return_amount,
    COALESCE(ss.total_store_profit, 0.00) AS store_profit
FROM 
    CustomerInfo ci
LEFT JOIN 
    RankedSales rs ON ci.total_orders > 5 AND rs.ws_order_number = (SELECT MAX(ws_order_number) FROM web_sales WHERE ws_bill_customer_sk = ci.c_customer_sk)
LEFT JOIN 
    TotalReturns tr ON ci.total_orders > 0 AND tr.cr_item_sk IN (SELECT DISTINCT ws_item_sk FROM web_sales WHERE ws_bill_customer_sk = ci.c_customer_sk)
LEFT JOIN 
    SalesSummary ss ON ss.s_store_sk IN (SELECT ss_store_sk FROM store_sales WHERE ss_customer_sk = ci.c_customer_sk)
WHERE 
    ci.total_spent > 100
ORDER BY 
    ci.total_spent DESC,
    ci.c_customer_sk
LIMIT 100;
