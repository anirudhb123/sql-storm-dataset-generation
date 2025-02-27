
WITH CustomerInfo AS (
    SELECT 
        c.c_customer_sk,
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating,
        COALESCE(hd.hd_buy_potential, 'unknown') AS buy_potential,
        COALESCE(hd.hd_dep_count, 0) AS dependency_count
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
),
SalesData AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_profit) AS total_profit,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM 
        web_sales ws
    LEFT JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2023
    GROUP BY 
        ws.ws_item_sk
),
ReturningCustomers AS (
    SELECT 
        cr.returning_customer_sk,
        COUNT(DISTINCT cr_order_number) AS total_returns
    FROM 
        catalog_returns cr
    WHERE 
        cr.returning_customer_sk IS NOT NULL
    GROUP BY 
        cr.returning_customer_sk
),
WarehouseShipping AS (
    SELECT 
        ws.ws_item_sk,
        COUNT(DISTINCT ws.ws_ship_mode_sk) AS distinct_ship_modes
    FROM 
        web_sales ws
    JOIN 
        warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    GROUP BY 
        ws.ws_item_sk
)
SELECT 
    ci.c_customer_id,
    ci.cd_gender,
    ci.cd_marital_status,
    COALESCE(SD.total_quantity, 0) AS total_quantity_sold,
    COALESCE(SD.total_profit, 0.00) AS total_profit_generated,
    COALESCE(RC.total_returns, 0) AS total_returned_orders,
    WS.distinct_ship_modes,
    ci.buy_potential,
    CASE 
        WHEN ci.cd_purchase_estimate IS NULL THEN 'Not estimated' 
        WHEN ci.cd_purchase_estimate < 1000 THEN 'Low spender'
        WHEN ci.cd_purchase_estimate BETWEEN 1000 AND 5000 THEN 'Average spender'
        ELSE 'High spender'
    END AS spending_category
FROM 
    CustomerInfo ci
LEFT JOIN 
    SalesData SD ON ci.c_customer_sk = SD.ws_item_sk
LEFT JOIN 
    ReturningCustomers RC ON ci.c_customer_sk = RC.returning_customer_sk
LEFT JOIN 
    WarehouseShipping WS ON SD.ws_item_sk = WS.ws_item_sk
WHERE 
    (ci.cd_gender = 'M' AND ci.buy_potential <> 'unknown' AND WS.distinct_ship_modes > 1) 
    OR 
    (ci.cd_gender = 'F' AND (ci.cd_marital_status = 'M' OR ci.cd_marital_status IS NULL))
ORDER BY 
    ci.c_customer_id;
