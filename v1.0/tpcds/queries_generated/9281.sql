
WITH CustomerStats AS (
    SELECT 
        cd_gender,
        COUNT(DISTINCT c_customer_sk) AS total_customers,
        AVG(cd_purchase_estimate) AS avg_purchase_estimate,
        SUM(cd_dep_count) AS total_dependents,
        SUM(cd_dep_employed_count) AS total_employed_deps,
        SUM(cd_dep_college_count) AS total_college_deps
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        cd_gender
),
SalesStats AS (
    SELECT 
        w.w_warehouse_id,
        SUM(ws_net_profit) AS total_net_profit,
        AVG(ws_net_paid_inc_tax) AS avg_net_paid,
        COUNT(DISTINCT ws_order_number) AS total_orders
    FROM 
        web_sales ws
    JOIN 
        warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    GROUP BY 
        w.w_warehouse_id
),
ReturnStats AS (
    SELECT 
        sr_reason_sk,
        COUNT(*) AS total_returns,
        SUM(sr_return_qty) AS total_return_qty,
        SUM(sr_return_amt_inc_tax) AS total_return_amt
    FROM 
        store_returns sr
    GROUP BY 
        sr_reason_sk
)
SELECT 
    cs.cd_gender,
    cs.total_customers,
    cs.avg_purchase_estimate,
    ss.w_warehouse_id,
    ss.total_net_profit,
    ss.avg_net_paid,
    rs.total_returns,
    rs.total_return_qty,
    rs.total_return_amt
FROM 
    CustomerStats cs
JOIN 
    SalesStats ss ON cs.total_customers > 100
JOIN 
    ReturnStats rs ON rs.total_returns > 10
WHERE 
    cs.total_dependents > 5
ORDER BY 
    ss.total_net_profit DESC, 
    cs.total_customers DESC 
LIMIT 100;
