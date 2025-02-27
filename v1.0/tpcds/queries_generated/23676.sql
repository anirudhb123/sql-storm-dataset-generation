
WITH demographic_analysis AS (
    SELECT 
        cd_gender,
        cd_marital_status,
        COUNT(c.c_customer_sk) AS customer_count,
        AVG(cd_purchase_estimate) AS avg_purchase_estimate,
        SUM(CASE WHEN cd_credit_rating IS NULL THEN 1 ELSE 0 END) AS null_credit_ratings
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY cd_gender, cd_marital_status
),
item_sales AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_sales,
        AVG(ws_sales_price) AS avg_price_per_unit,
        SUM(CASE WHEN ws_sales_price IS NULL THEN 1 ELSE 0 END) AS null_sales_prices
    FROM web_sales
    GROUP BY ws_item_sk
),
inventory_status AS (
    SELECT 
        inv_item_sk,
        SUM(inv_quantity_on_hand) AS total_quantity_on_hand
    FROM inventory
    GROUP BY inv_item_sk
),
combined_data AS (
    SELECT 
        da.cd_gender,
        da.cd_marital_status,
        ia.inv_item_sk,
        ia.total_quantity_on_hand,
        sa.total_sales,
        sa.avg_price_per_unit,
        da.customer_count,
        da.avg_purchase_estimate,
        da.null_credit_ratings,
        sa.null_sales_prices
    FROM demographic_analysis da
    FULL OUTER JOIN item_sales sa ON da.customer_count > 10 AND da.cd_gender = 'F'
    LEFT JOIN inventory_status ia ON ia.inv_item_sk IS NOT NULL AND sa.ws_item_sk = ia.inv_item_sk
),
final_selection AS (
    SELECT 
        *,
        NTILE(4) OVER (PARTITION BY cd_marital_status ORDER BY avg_purchase_estimate DESC) AS purchase_segment,
        ROW_NUMBER() OVER (PARTITION BY cd_gender ORDER BY total_sales DESC) AS sales_rank
    FROM combined_data
    WHERE (customer_count IS NOT NULL OR total_sales IS NOT NULL)
      AND (total_quantity_on_hand < 50 OR purchase_segment = 1)
)

SELECT 
    cd_gender,
    cd_marital_status,
    COUNT(*) AS record_count,
    SUM(customer_count) AS total_customers,
    SUM(total_sales) AS total_item_sales,
    AVG(avg_purchase_estimate) AS avg_customer_purchase,
    STRING_AGG(CONCAT('Item: ', inv_item_sk, ' Sales: ', total_sales), '; ') AS item_sales_summary
FROM final_selection
WHERE purchase_segment = 1
GROUP BY cd_gender, cd_marital_status
HAVING SUM(total_sales) > 1000
ORDER BY total_item_sales DESC, cd_gender ASC NULLS LAST;
