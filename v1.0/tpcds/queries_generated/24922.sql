
WITH RankedStoreSales AS (
    SELECT 
        ss_store_sk,
        ss_item_sk,
        SUM(ss_quantity) AS total_quantity,
        RANK() OVER (PARTITION BY ss_store_sk ORDER BY SUM(ss_quantity) DESC) AS sales_rank
    FROM 
        store_sales
    GROUP BY 
        ss_store_sk, ss_item_sk
),
StoreInventory AS (
    SELECT 
        inv_w.warehouse,
        inv.inv_quantity_on_hand,
        i.i_item_desc
    FROM 
        inventory inv
    JOIN 
        warehouse inv_w ON inv.inv_warehouse_sk = inv_w.w_warehouse_sk
    JOIN 
        item i ON inv.inv_item_sk = i.i_item_sk
    WHERE
        inv.inv_quantity_on_hand IS NOT NULL
),
CustomerDemographics AS (
    SELECT 
        cd_demo_sk,
        cd_gender,
        COUNT(DISTINCT c_customer_sk) AS customer_count
    FROM 
        customer_demographics cd
    LEFT JOIN 
        customer c ON cd.cd_demo_sk = c.c_current_cdemo_sk
    GROUP BY 
        cd_demo_sk, cd_gender
)
SELECT 
    ss.ss_store_sk,
    si.warehouse,
    si.i_item_desc,
    COALESCE(rs.total_quantity, 0) AS total_quantity,
    cd.customer_count,
    CASE 
        WHEN cd.customer_count > 100 THEN 'High'
        WHEN cd.customer_count BETWEEN 51 AND 100 THEN 'Medium'
        ELSE 'Low' 
    END AS customer_segment,
    ROW_NUMBER() OVER (PARTITION BY ss.ss_store_sk ORDER BY COALESCE(rs.total_quantity, 0) DESC) AS store_rank
FROM 
    RankedStoreSales rs
FULL OUTER JOIN 
    StoreInventory si ON si.inv_item_sk = rs.ss_item_sk
LEFT JOIN 
    CustomerDemographics cd ON cd.cd_demo_sk = si.inv_item_sk % 10 -- whimsical join for testing corner case
WHERE 
    (COALESCE(rs.total_quantity, 0) > 0 OR cd.customer_count IS NULL)
    AND (si.i_item_desc IS NOT NULL AND si.i_item_desc LIKE '%Special%')
ORDER BY 
    ss.ss_store_sk, total_quantity DESC, customer_segment
FETCH FIRST 100 ROWS ONLY;
