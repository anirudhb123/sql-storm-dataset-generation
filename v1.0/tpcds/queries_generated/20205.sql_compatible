
WITH RankedSales AS (
    SELECT 
        ss_item_sk,
        SUM(ss_sales_price) AS total_sales,
        RANK() OVER (PARTITION BY ss_item_sk ORDER BY SUM(ss_sales_price) DESC) AS sales_rank
    FROM 
        store_sales
    GROUP BY 
        ss_item_sk
),
SelectedItems AS (
    SELECT 
        i.i_item_id,
        i.i_item_desc,
        r.r_reason_desc,
        inv.inv_quantity_on_hand
    FROM 
        item i
    LEFT JOIN 
        reason r ON r.r_reason_sk = (
            SELECT 
                cr_reason_sk 
            FROM 
                catalog_returns 
            WHERE 
                cr_item_sk = i.i_item_sk 
            ORDER BY 
                cr_return_quantity DESC 
            FETCH FIRST 1 ROW ONLY
        )
    JOIN 
        inventory inv ON inv.inv_item_sk = i.i_item_sk
)
SELECT 
    si.i_item_id,
    si.i_item_desc,
    COALESCE(si.inv_quantity_on_hand, 0) AS available_stock,
    COALESCE(rs.total_sales, 0.00) AS total_sales_value,
    CASE 
        WHEN si.inv_quantity_on_hand IS NULL THEN 'Stock data missing'
        WHEN COALESCE(rs.total_sales, 0) < 100 THEN 'Low sales'
        ELSE 'Healthy sales'
    END AS sales_status
FROM 
    SelectedItems si
FULL OUTER JOIN 
    RankedSales rs ON si.i_item_id = (SELECT i.i_item_id FROM item i WHERE i.i_item_sk = rs.ss_item_sk)
WHERE 
    (si.inv_quantity_on_hand IS NOT NULL OR rs.total_sales IS NOT NULL)
    AND (UPPER(si.i_item_desc) LIKE '%FISH%' OR UPPER(si.i_item_desc) LIKE '%CHICKEN%')
ORDER BY 
    sales_status, 
    available_stock DESC 
LIMIT 100
OFFSET (SELECT COUNT(*) FROM customer WHERE c_birth_year < 1970);
