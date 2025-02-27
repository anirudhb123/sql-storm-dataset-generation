
WITH AverageSales AS (
    SELECT 
        ws_item_sk,
        AVG(ws_net_paid) AS avg_sales
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN 1 AND 30
    GROUP BY 
        ws_item_sk
),
TopItems AS (
    SELECT 
        i_item_sk, 
        i_item_desc, 
        ROW_NUMBER() OVER (PARTITION BY i_item_sk ORDER BY i_item_sk DESC) AS rn
    FROM 
        item
    WHERE 
        i_size IS NOT NULL AND i_current_price > 20
),
CustomerStats AS (
    SELECT
        c.customer_sk,
        COUNT(DISTINCT CASE WHEN cd_gender = 'F' THEN cd_demo_sk END) AS female_count,
        COUNT(DISTINCT CASE WHEN cd_gender = 'M' THEN cd_demo_sk END) AS male_count,
        COALESCE(SUM(cd_purchase_estimate), 0) AS total_purchase_estimate
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY 
        c.customer_sk
),
StoreInventory AS (
    SELECT 
        inv.inv_item_sk,
        SUM(inv.inv_quantity_on_hand) AS total_quantity,
        ROW_NUMBER() OVER (PARTITION BY inv.inv_item_sk ORDER BY SUM(inv.inv_quantity_on_hand) DESC) AS item_rank
    FROM 
        inventory inv
    GROUP BY 
        inv.inv_item_sk
)
SELECT 
    c.c_last_name,
    c.c_first_name,
    COALESCE(avg.avg_sales, 0) AS average_sales,
    st.total_quantity,
    cs.female_count,
    cs.male_count,
    cs.total_purchase_estimate
FROM 
    customer c
LEFT JOIN AverageSales avg ON c.c_first_shipto_date_sk = avg.ws_item_sk
LEFT JOIN StoreInventory st ON st.inv_item_sk = c.c_current_addr_sk
JOIN CustomerStats cs ON cs.customer_sk = c.c_customer_sk
WHERE 
    cs.total_purchase_estimate > (
        SELECT AVG(total_purchase_estimate) 
        FROM CustomerStats
    ) 
    AND (c.c_birth_country NOT IN ('USA', 'Canada') OR c.c_birth_country IS NULL)
ORDER BY 
    average_sales DESC,
    total_quantity ASC
FETCH FIRST 100 ROWS ONLY;
