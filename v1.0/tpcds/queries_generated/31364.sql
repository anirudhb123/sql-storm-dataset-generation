
WITH RECURSIVE SalesAggregate AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_ext_sales_price) AS total_sales
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk
    
    UNION ALL
    
    SELECT 
        cs_item_sk, 
        SUM(cs_quantity) + a.total_quantity,
        SUM(cs_ext_sales_price) + a.total_sales
    FROM 
        catalog_sales cs
    INNER JOIN 
        SalesAggregate a ON cs_item_sk = a.ws_item_sk
    GROUP BY 
        cs_item_sk
),
CustomerInfo AS (
    SELECT 
        c.c_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        COALESCE(c.c_birth_year, 0) AS birth_year,
        COALESCE(cd.cd_purchase_estimate, 0) AS purchase_estimate,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS rank
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
MostValuableCustomers AS (
    SELECT 
        ci.c_customer_sk,
        ci.cd_gender,
        ci.purchase_estimate,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_net_profit) AS total_profit
    FROM 
        CustomerInfo ci
    LEFT JOIN 
        web_sales ws ON ci.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        ci.c_customer_sk, ci.cd_gender, ci.purchase_estimate
    HAVING 
        SUM(ws.ws_net_profit) > 1000
)
SELECT 
    w.w_warehouse_name,
    COALESCE(SUM(sa.total_quantity), 0) AS total_quantity_sold,
    COALESCE(SUM(mvc.total_profit), 0) AS total_profit,
    COUNT(DISTINCT CASE WHEN mvc.c_customer_sk IS NOT NULL THEN mvc.c_customer_sk END) AS unique_customers,
    COUNT(DISTINCT ws.ws_order_number) AS total_web_orders
FROM 
    warehouse w
LEFT JOIN 
    inventory inv ON w.w_warehouse_sk = inv.inv_warehouse_sk
LEFT JOIN 
    SalesAggregate sa ON inv.inv_item_sk = sa.ws_item_sk
LEFT JOIN 
    MostValuableCustomers mvc ON mvc.c_customer_sk IN (SELECT DISTINCT ws_bill_customer_sk FROM web_sales)
LEFT JOIN 
    web_sales ws ON ws.ws_warehouse_sk = w.w_warehouse_sk
WHERE 
    inv.inv_quantity_on_hand > 0
GROUP BY 
    w.warehouse_name
ORDER BY 
    total_profit DESC;
