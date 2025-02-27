
WITH RankedSales AS (
    SELECT 
        ws.web_site_id,
        ws_item_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        RANK() OVER (PARTITION BY ws.web_site_id ORDER BY SUM(ws_ext_sales_price) DESC) AS sales_rank
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk BETWEEN 20220101 AND 20221231
    GROUP BY 
        ws.web_site_id, ws_item_sk
),
DiscountedSales AS (
    SELECT 
        cs.cs_item_sk,
        SUM(cs.cs_ext_sales_price) AS total_discounted_sales
    FROM 
        catalog_sales cs
    JOIN 
        promotion p ON cs.cs_promo_sk = p.p_promo_sk
    WHERE 
        p.p_discount_active = 'Y'
    GROUP BY 
        cs.cs_item_sk
),
WarehouseInventory AS (
    SELECT 
        inv.inv_item_sk,
        SUM(inv.inv_quantity_on_hand) AS total_inventory
    FROM 
        inventory inv
    GROUP BY 
        inv.inv_item_sk
),
SaleMetrics AS (
    SELECT 
        r.ws_item_sk,
        COALESCE(r.total_sales, 0) AS total_sales,
        COALESCE(ds.total_discounted_sales, 0) AS total_discounted_sales,
        COALESCE(wi.total_inventory, 0) AS total_inventory,
        CASE 
            WHEN COALESCE(wi.total_inventory, 0) = 0 THEN NULL
            ELSE (COALESCE(r.total_sales, 0) / COALESCE(wi.total_inventory, 0))
        END AS sales_to_inventory_ratio
    FROM 
        RankedSales r
    LEFT JOIN 
        DiscountedSales ds ON r.ws_item_sk = ds.cs_item_sk
    LEFT JOIN 
        WarehouseInventory wi ON r.ws_item_sk = wi.inv_item_sk
)
SELECT 
    s.ws_item_sk,
    s.total_sales,
    s.total_discounted_sales,
    s.total_inventory,
    s.sales_to_inventory_ratio,
    CASE 
        WHEN s.sales_to_inventory_ratio IS NULL THEN 'No Inventory'
        WHEN s.sales_to_inventory_ratio > 1 THEN 'High Sales'
        ELSE 'Balanced'
    END AS sales_status
FROM 
    SaleMetrics s
WHERE 
    s.total_sales > 5000 OR 
    s.sales_to_inventory_ratio IS NULL
ORDER BY 
    s.total_sales DESC NULLS LAST
LIMIT 100;
