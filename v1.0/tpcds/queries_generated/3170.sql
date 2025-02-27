
WITH RankedCustomers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) as rank
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
), 
TopConsumers AS (
    SELECT 
        rc.c_customer_sk,
        rc.c_first_name,
        rc.c_last_name,
        rc.cd_gender,
        rc.cd_purchase_estimate
    FROM 
        RankedCustomers rc
    WHERE 
        rc.rank <= 5
), 
SalesSummary AS (
    SELECT 
        w.w_warehouse_id,
        SUM(ws.ws_net_profit) as total_net_profit,
        COUNT(DISTINCT ws.ws_order_number) as total_orders,
        AVG(ws.ws_sales_price) as avg_sales_price
    FROM 
        web_sales ws
    JOIN 
        warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    GROUP BY 
        w.w_warehouse_id
)
SELECT 
    tc.c_first_name,
    tc.c_last_name,
    tc.cd_gender,
    ts.total_net_profit,
    ts.total_orders,
    ts.avg_sales_price,
    CASE 
        WHEN ts.total_net_profit > 10000 THEN 'High Roller'
        WHEN ts.total_net_profit BETWEEN 5000 AND 10000 THEN 'Moderate Spender'
        ELSE 'Budget Shopper'
    END AS customer_category
FROM 
    TopConsumers tc
LEFT JOIN 
    SalesSummary ts ON tc.c_customer_sk = ts.ws_bill_customer_sk
WHERE 
    ts.total_orders IS NOT NULL
    AND (tc.cd_gender = 'M' OR (tc.cd_gender = 'F' AND ts.total_net_profit IS NOT NULL))
ORDER BY 
    ts.total_net_profit DESC;
