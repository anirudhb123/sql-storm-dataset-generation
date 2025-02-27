
WITH RankedSales AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_profit) AS total_net_profit,
        DENSE_RANK() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_net_profit) DESC) AS rank_per_item
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk
),
TopWebSales AS (
    SELECT 
        r.ws_item_sk,
        r.total_quantity,
        r.total_net_profit,
        i.i_item_desc,
        i.i_current_price
    FROM 
        RankedSales r
    JOIN 
        item i ON r.ws_item_sk = i.i_item_sk
    WHERE 
        r.rank_per_item <= 10
),
CustomerInfo AS (
    SELECT 
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        COUNT(DISTINCT cd.cd_demo_sk) AS demo_count
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        c.c_customer_id, cd.cd_gender, cd.cd_marital_status, cd.cd_purchase_estimate
),
SalesByCustomer AS (
    SELECT 
        c.c_customer_id, 
        SUM(ws.ws_net_profit) AS total_profit,
        AVG(ws.ws_net_paid) AS avg_net_paid,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    GROUP BY 
        c.c_customer_id
),
CustomerPerformance AS (
    SELECT 
        ci.c_customer_id,
        ci.cd_gender,
        ci.cd_marital_status,
        ci.cd_purchase_estimate,
        COALESCE(sp.total_profit, 0) AS customer_profit,
        COALESCE(sp.order_count, 0) AS customer_orders,
        CASE 
            WHEN sp.total_profit >= 1000 THEN 'High Value'
            WHEN sp.total_profit >= 100 THEN 'Medium Value'
            ELSE 'Low Value' 
        END AS customer_value
    FROM 
        CustomerInfo ci
    LEFT JOIN 
        SalesByCustomer sp ON ci.c_customer_id = sp.c_customer_id
)
SELECT 
    c.c_customer_id,
    cp.cd_gender,
    cp.customer_value,
    ts.total_net_profit,
    ts.total_quantity,
    SUM(CASE WHEN ts.total_net_profit IS NULL THEN 0 ELSE ts.total_net_profit END) OVER (PARTITION BY cp.customer_value) AS net_profit_per_customer_value,
    ROW_NUMBER() OVER (PARTITION BY cp.customer_value ORDER BY ts.total_net_profit DESC) AS rank_by_value
FROM 
    CustomerPerformance cp
LEFT JOIN 
    TopWebSales ts ON cp.c_customer_id = ts.ws_item_sk
WHERE 
    (cp.customer_orders IS NULL OR cp.customer_orders > 0)
    AND (cp.cd_gender IS NOT NULL OR cp.customer_value = 'Low Value')
ORDER BY 
    cp.customer_value ASC, ts.total_net_profit DESC
LIMIT 50 OFFSET 0;
