
WITH RankedSales AS (
    SELECT 
        ws.web_site_sk, 
        ws_ship_date_sk, 
        ws_item_sk, 
        ws_quantity, 
        ws_ext_sales_price,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_ext_sales_price DESC) AS rank_per_item
    FROM 
        web_sales ws
    WHERE 
        ws_ship_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2023)
), 
ItemInventory AS (
    SELECT 
        inv.inv_item_sk, 
        SUM(inv.inv_quantity_on_hand) AS total_quantity 
    FROM 
        inventory inv
    WHERE 
        inv_date_sk = (SELECT MAX(inv_date_sk) FROM inventory)
    GROUP BY 
        inv.inv_item_sk
), 
CustomerDetails AS (
    SELECT 
        cd_cdemo_sk, 
        cd_gender, 
        cd_marital_status,
        COUNT(DISTINCT c.c_customer_id) AS total_customers
    FROM 
        customer c
        JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        cd_marital_status = 'M' AND cd_gender = 'F'
    GROUP BY 
        cd_cdemo_sk, 
        cd_gender, 
        cd_marital_status
),
TopSellingItems AS (
    SELECT 
        ris.web_site_sk, 
        ri.inv_item_sk, 
        ri.total_quantity, 
        ris.ws_ext_sales_price
    FROM 
        RankedSales ris
        JOIN ItemInventory ri ON ris.ws_item_sk = ri.inv_item_sk
    WHERE 
        ris.rank_per_item <= 5
)
SELECT 
    cs.total_customers, 
    tsi.inv_item_sk, 
    tsi.ws_ext_sales_price,
    CASE 
        WHEN tsi.total_quantity IS NOT NULL THEN tsi.total_quantity
        ELSE 0
    END AS current_inventory,
    COUNT(*) OVER () AS total_records
FROM 
    TopSellingItems tsi
    JOIN CustomerDetails cs ON cs.cd_cdemo_sk = (
        SELECT 
            cd_demo_sk 
        FROM 
            customer 
        ORDER BY 
            c_customer_sk 
        LIMIT 1 OFFSET (SELECT COUNT(*) FROM customer) / 2
    )
ORDER BY 
    tsi.ws_ext_sales_price DESC
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY;
