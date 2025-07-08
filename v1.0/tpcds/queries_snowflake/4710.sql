
WITH SalesData AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS total_orders,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_sales_price) DESC) AS sales_rank
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk BETWEEN 2450000 AND 2450583
    GROUP BY 
        ws.ws_item_sk
), CustomerData AS (
    SELECT 
        c.c_customer_sk,
        CASE 
            WHEN cd.cd_gender = 'M' THEN 'Male'
            WHEN cd.cd_gender = 'F' THEN 'Female'
            ELSE 'Other'
        END AS gender,
        COUNT(DISTINCT cs.cs_order_number) AS total_catalog_orders,
        COALESCE(SUM(cs.cs_sales_price), 0) AS total_catalog_sales
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        catalog_sales cs ON c.c_customer_sk = cs.cs_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, cd.cd_gender
), InventoryData AS (
    SELECT 
        inv.inv_item_sk,
        SUM(CASE WHEN inv.inv_quantity_on_hand IS NULL THEN 0 ELSE inv.inv_quantity_on_hand END) AS total_inventory
    FROM 
        inventory inv
    GROUP BY 
        inv.inv_item_sk
)

SELECT 
    id.ws_item_sk,
    id.total_sales,
    id.total_orders,
    cd.gender,
    cd.total_catalog_orders,
    cd.total_catalog_sales,
    COALESCE(inv.total_inventory, 0) AS inventory_count
FROM 
    SalesData id
INNER JOIN 
    CustomerData cd ON cd.c_customer_sk = (
        SELECT 
            c.c_customer_sk 
        FROM 
            customer c 
        WHERE 
            EXISTS (
                SELECT 1 
                FROM web_sales ws 
                WHERE ws.ws_item_sk = id.ws_item_sk AND ws.ws_bill_customer_sk = c.c_customer_sk
            )
        LIMIT 1
    )
LEFT JOIN 
    InventoryData inv ON inv.inv_item_sk = id.ws_item_sk
WHERE 
    id.sales_rank <= 10
ORDER BY 
    id.total_sales DESC;
