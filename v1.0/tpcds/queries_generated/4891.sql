
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        SUM(ws.ws_net_paid) AS total_web_sales,
        SUM(cs.cs_net_paid) AS total_catalog_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_web_orders,
        COUNT(DISTINCT cs.cs_order_number) AS total_catalog_orders
    FROM 
        customer AS c
    LEFT JOIN 
        web_sales AS ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN 
        catalog_sales AS cs ON c.c_customer_sk = cs.cs_bill_customer_sk
    GROUP BY 
        c.c_customer_sk
),
WarehouseInventory AS (
    SELECT 
        inv.inv_item_sk,
        SUM(inv.inv_quantity_on_hand) AS total_inventory
    FROM 
        inventory AS inv
    GROUP BY 
        inv.inv_item_sk
),
DetailedSales AS (
    SELECT 
        CASE 
            WHEN cs.cs_sales_price IS NOT NULL THEN 'Catalog'
            WHEN ws.ws_sales_price IS NOT NULL THEN 'Web'
            ELSE 'Unknown'
        END AS sales_channel,
        COALESCE(ws.ws_net_profit, 0) AS web_profit,
        COALESCE(cs.cs_net_profit, 0) AS catalog_profit,
        COALESCE(ws.ws_net_paid_inc_tax, 0) + COALESCE(cs.cs_net_paid_inc_tax, 0) AS total_sales
    FROM 
        web_sales AS ws
    FULL OUTER JOIN 
        catalog_sales AS cs ON ws.ws_item_sk = cs.cs_item_sk
)
SELECT 
    c.c_first_name,
    c.c_last_name,
    cs.total_web_sales,
    cs.total_catalog_sales,
    wi.total_inventory,
    ds.sales_channel,
    ds.total_sales,
    ds.web_profit,
    ds.catalog_profit
FROM 
    customer AS c
LEFT JOIN 
    CustomerSales AS cs ON c.c_customer_sk = cs.c_customer_sk
LEFT JOIN 
    WarehouseInventory AS wi ON wi.inv_item_sk IN (SELECT i.i_item_sk FROM item AS i WHERE i.i_manager_id = c.c_customer_sk)
LEFT JOIN 
    DetailedSales AS ds ON ds.total_sales > 100
WHERE 
    (cs.total_web_sales IS NOT NULL OR cs.total_catalog_sales IS NOT NULL)
    AND c.c_birth_year < 1995
ORDER BY 
    cs.total_web_sales DESC, 
    cs.total_catalog_sales DESC
LIMIT 100;
