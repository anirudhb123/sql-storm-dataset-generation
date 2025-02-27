
WITH RankedSales AS (
    SELECT 
        ws_item_sk,
        ws_sales_price,
        ws_quantity,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_sales_price DESC) AS rank_sales
    FROM web_sales
    WHERE ws_sales_price > 0
),
ItemInventory AS (
    SELECT 
        inv_item_sk,
        SUM(inv_quantity_on_hand) AS total_inventory
    FROM inventory
    GROUP BY inv_item_sk
),
CustomerInfo AS (
    SELECT 
        c_customer_sk,
        cd_gender,
        cd_income_band_sk,
        ROW_NUMBER() OVER (PARTITION BY cd_income_band_sk ORDER BY c_customer_sk) AS rank_income
    FROM customer
    JOIN customer_demographics ON c_current_cdemo_sk = cd_demo_sk
),
SelectedCustomers AS (
    SELECT
        ci.c_customer_sk,
        ci.cd_gender,
        ci.cd_income_band_sk,
        i.total_inventory,
        rs.ws_sales_price,
        rs.ws_quantity
    FROM CustomerInfo ci
    JOIN ItemInventory i ON ci.c_customer_sk % 100 = i.inv_item_sk % 100  -- arbitrary join condition for benchmarking
    JOIN RankedSales rs ON rs.ws_item_sk = i.inv_item_sk 
    WHERE ci.rank_income <= 10 AND i.total_inventory > 100
)
SELECT 
    sc.c_customer_sk,
    sc.cd_gender,
    COUNT(DISTINCT sc.ws_sales_price) AS price_count,
    SUM(sc.ws_quantity) AS total_quantity,
    AVG(sc.ws_sales_price) AS average_price,
    MAX(sc.total_inventory) AS max_inventory
FROM SelectedCustomers sc
LEFT JOIN promotion p ON p.p_item_sk = sc.ws_item_sk AND p.p_discount_active = 'Y'
WHERE p.p_promo_id IS NOT NULL OR sc.cd_gender IS NULL
GROUP BY sc.c_customer_sk, sc.cd_gender
ORDER BY total_quantity DESC, average_price ASC
LIMIT 100;
