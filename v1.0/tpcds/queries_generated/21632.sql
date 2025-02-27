
WITH sales_data AS (
    SELECT 
        ss_store_sk,
        ss_item_sk,
        SUM(ss_sales_price) AS total_sales,
        COUNT(DISTINCT ss_ticket_number) AS transactions_count,
        ROW_NUMBER() OVER (PARTITION BY ss_store_sk ORDER BY SUM(ss_sales_price) DESC) AS sales_rank
    FROM 
        store_sales
    GROUP BY 
        ss_store_sk, ss_item_sk
),
top_stores AS (
    SELECT 
        sd.ss_store_sk,
        SUM(sd.total_sales) AS combined_sales
    FROM 
        sales_data sd
    WHERE 
        sd.sales_rank <= 5
    GROUP BY 
        sd.ss_store_sk
),
inventory_info AS (
    SELECT 
        inv.inv_item_sk,
        SUM(CASE WHEN inv.inv_quantity_on_hand IS NULL THEN 0 ELSE inv.inv_quantity_on_hand END) AS total_inventory
    FROM 
        inventory inv
    GROUP BY 
        inv.inv_item_sk
),
combined_results AS (
    SELECT 
        ts.ss_store_sk,
        ts.combined_sales,
        COALESCE(ii.total_inventory, 0) AS available_inventory
    FROM 
        top_stores ts
    LEFT JOIN 
        inventory_info ii ON ii.inv_item_sk = (SELECT MIN(si.ss_item_sk) FROM sales_data si WHERE si.ss_store_sk = ts.ss_store_sk)
)
SELECT 
    cr.ss_store_sk,
    cr.combined_sales,
    cr.available_inventory,
    CASE 
        WHEN cr.available_inventory > cr.combined_sales THEN 'Excess Inventory'
        WHEN cr.available_inventory < cr.combined_sales THEN 'Inventory Shortage'
        ELSE 'Balanced Inventory'
    END AS inventory_status,
    CONCAT('Store ', cr.ss_store_sk, ' has ', cr.available_inventory, ' units available')
FROM 
    combined_results cr
WHERE
    cr.available_inventory IS NOT NULL
ORDER BY 
    cr.combined_sales DESC
LIMIT 10;
