
WITH RECURSIVE sales_summary AS (
    SELECT
        ws_order_number,
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws_order_number ORDER BY SUM(ws_sales_price) DESC) AS rank
    FROM web_sales
    GROUP BY ws_order_number, ws_item_sk
),
customer_info AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_income_band_sk,
        ci.region
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN (
        SELECT 
            ha.hd_demo_sk, 
            CASE 
                WHEN ib.ib_income_band_sk IS NOT NULL THEN 'High' 
                ELSE 'Low' 
            END AS region
        FROM household_demographics ha
        LEFT JOIN income_band ib ON ha.hd_income_band_sk = ib.ib_income_band_sk
    ) ci ON cd.cd_demo_sk = ci.hd_demo_sk
),
inventory_status AS (
    SELECT
        inv.inv_item_sk,
        SUM(inv.inv_quantity_on_hand) AS total_inventory,
        MAX(inv.inv_date_sk) AS last_updated
    FROM inventory inv
    GROUP BY inv.inv_item_sk
    HAVING SUM(inv.inv_quantity_on_hand) > 0
)
SELECT
    ci.c_first_name,
    ci.c_last_name,
    ci.cd_gender,
    si.total_quantity,
    si.total_sales,
    is.total_inventory,
    RANK() OVER (ORDER BY si.total_sales DESC) AS sales_rank,
    COALESCE(ci.region, 'Unknown') AS customer_region
FROM sales_summary si
JOIN customer_info ci ON si.ws_item_sk = ci.c_customer_sk
LEFT JOIN inventory_status is ON si.ws_item_sk = is.inv_item_sk
WHERE si.rank = 1
  AND (is.total_inventory > 100 OR ci.cd_gender = 'F')
ORDER BY sales_rank, ci.c_last_name;
