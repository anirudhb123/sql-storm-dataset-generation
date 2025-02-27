
WITH RankedSales AS (
    SELECT 
        ws.web_site_id, 
        SUM(ws.ws_sales_price) AS total_sales, 
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        DENSE_RANK() OVER (PARTITION BY ws.web_site_id ORDER BY SUM(ws.ws_sales_price) DESC) AS sales_rank
    FROM web_sales ws
    WHERE ws.ws_sold_date_sk BETWEEN 2458458 AND 2458468
    GROUP BY ws.web_site_id
),
CustomerProfile AS (
    SELECT 
        c.c_customer_id, 
        cd.cd_gender,
        cd.cd_marital_status, 
        cd.cd_credit_rating,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_marital_status ORDER BY c.c_birth_year DESC) AS marital_rank
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE cd.cd_credit_rating IS NOT NULL
),
WeatherPatterns AS (
    SELECT 
        d.d_date,
        CASE 
            WHEN d.d_dow IN (1, 7) THEN 'Weekend'
            WHEN d.d_dow BETWEEN 2 AND 6 THEN 'Weekday'
            ELSE 'Unknown'
        END AS day_type
    FROM date_dim d
    WHERE d.d_year = 2023
),
WarehouseInventory AS (
    SELECT 
        inv.inv_warehouse_sk,
        SUM(inv.inv_quantity_on_hand) AS total_quantity,
        AVG(inv.inv_quantity_on_hand) AS avg_quantity
    FROM inventory inv
    GROUP BY inv.inv_warehouse_sk
)
SELECT 
    cp.c_customer_id, 
    cp.cd_gender,
    COALESCE(SR.return_count, 0) AS return_count,
    COALESCE(ws.total_sales, 0) AS total_sales,
    ws.total_sales / NULLIF(COALESCE(SR.return_count, 0), 0) AS sales_per_return,
    CASE 
        WHEN wp.wp_web_page_id IS NOT NULL THEN 'Active'
        ELSE 'Inactive'
    END AS web_page_status,
    CASE 
        WHEN wi.avg_quantity < 10 THEN 'Low Stock'
        WHEN wi.avg_quantity BETWEEN 10 AND 100 THEN 'Medium Stock'
        ELSE 'High Stock'
    END AS inventory_status    
FROM CustomerProfile cp
LEFT JOIN RankedSales ws ON cp.c_customer_id = ws.web_site_id
LEFT JOIN (
    SELECT 
        sr_returning_customer_sk, 
        COUNT(*) AS return_count
    FROM store_returns 
    GROUP BY sr_returning_customer_sk
) SR ON cp.c_customer_id = SR.sr_returning_customer_sk
LEFT JOIN warehouse w ON w.w_warehouse_sk = (SELECT DISTINCT inv.inv_warehouse_sk FROM WarehouseInventory inv WHERE inv.total_quantity > 0 LIMIT 1)
LEFT JOIN web_page wp ON wp.wp_web_page_id = (SELECT wp.web_page_id FROM web_page wp WHERE wp.wp_creation_date_sk <= (SELECT max(d.d_date_sk) FROM date_dim d WHERE d.d_year = 2023) LIMIT 1)
LEFT JOIN WarehouseInventory wi ON wi.inv_warehouse_sk = w.w_warehouse_sk
WHERE cp.marital_rank <= 10
ORDER BY total_sales DESC, cp.c_customer_id;
