
WITH SalesSummary AS (
    SELECT 
        c.c_customer_sk,
        c.c_state,
        SUM(ws.ws_net_profit) AS total_profit,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        AVG(ws.ws_net_paid) AS avg_order_value
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    WHERE 
        c.c_birth_month = 12 AND c.c_birth_day >= 20
    GROUP BY 
        c.c_customer_sk, c.c_state
), 
CustomerDemographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cs.c_customer_sk
    FROM 
        customer_demographics cd
    JOIN 
        customer cs ON cd.cd_demo_sk = cs.c_current_cdemo_sk
), 
WarehouseSales AS (
    SELECT 
        w.w_warehouse_id,
        SUM(ws.ws_ext_sales_price) AS total_sales
    FROM 
        warehouse w
    JOIN 
        web_sales ws ON w.w_warehouse_sk = ws.ws_warehouse_sk
    GROUP BY 
        w.w_warehouse_id
)
SELECT 
    cs.c_customer_sk,
    cd.cd_gender,
    cd.cd_marital_status,
    SUM(ss.total_profit) AS aggregate_profit,
    COUNT(ss.total_orders) AS total_orders,
    AVG(ss.avg_order_value) AS avg_order_value,
    ws.w_warehouse_id,
    ws.total_sales
FROM 
    SalesSummary ss
JOIN 
    CustomerDemographics cd ON ss.c_customer_sk = cd.cs.c_customer_sk
JOIN 
    WarehouseSales ws ON ss.c_state = ws.w.w_state
WHERE 
    ss.total_profit > 1000
GROUP BY 
    cs.c_customer_sk, cd.cd_gender, cd.cd_marital_status, ws.w_warehouse_id, ws.total_sales
ORDER BY 
    aggregate_profit DESC
LIMIT 100;
