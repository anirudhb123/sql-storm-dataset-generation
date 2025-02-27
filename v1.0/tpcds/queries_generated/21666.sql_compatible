
WITH RankedSales AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_sales_price) AS total_sales,
        DENSE_RANK() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_sales_price) DESC) AS sales_rank
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk
),
HighVolumeItems AS (
    SELECT 
        item.i_item_id,
        item.i_product_name,
        COALESCE(cdemo.cd_gender, 'U') AS gender,
        COALESCE(hdemo.hd_income_band_sk, -1) AS income_band_sk
    FROM 
        item
    LEFT JOIN 
        customer_demographics cdemo ON item.i_item_sk = cdemo.cd_demo_sk
    LEFT JOIN 
        household_demographics hdemo ON cdemo.cd_demo_sk = hdemo.hd_demo_sk
    WHERE 
        EXISTS (
            SELECT 1 
            FROM web_sales ws 
            WHERE ws.ws_item_sk = item.i_item_sk AND ws.ws_quantity > 100
        )
),
AggregateInfo AS (
    SELECT 
        hvi.i_item_id,
        hvi.i_product_name,
        hvi.gender,
        hvi.income_band_sk,
        SUM(rws.total_sales) AS cumulative_sales,
        COUNT(DISTINCT ws_order_number) AS order_count,
        CASE 
            WHEN SUM(rws.total_sales) IS NULL THEN 'NO SALES'
            WHEN SUM(rws.total_sales) >= 1000 THEN 'HIGH SALES'
            ELSE 'LOW SALES'
        END AS sales_category
    FROM 
        HighVolumeItems hvi
    LEFT JOIN 
        RankedSales rws ON hvi.i_item_id = rws.ws_item_sk
    LEFT JOIN 
        web_sales ws ON hvi.i_item_id = ws.ws_item_sk
    GROUP BY 
        hvi.i_item_id, hvi.i_product_name, hvi.gender, hvi.income_band_sk
)
SELECT 
    ai.i_item_id,
    ai.i_product_name,
    ai.gender,
    ai.income_band_sk,
    ai.cumulative_sales,
    ai.order_count,
    ai.sales_category,
    CASE 
        WHEN ai.sales_category = 'HIGH SALES' AND ai.cumulative_sales > 5000 THEN 'TOP PERFORMER'
        WHEN ai.order_count IS NULL THEN 'UNPREDICTABLE'
        ELSE 'AVERAGE'
    END AS performance_rating
FROM 
    AggregateInfo ai 
FULL OUTER JOIN 
    (SELECT DISTINCT i_item_id FROM item WHERE i_item_sk IS NOT NULL) non_performers ON ai.i_item_id = non_performers.i_item_id
WHERE 
    (ai.cumulative_sales > 0 OR non_performers.i_item_id IS NOT NULL)
    AND (ai.gender = 'F' OR ai.gender IS NULL)
ORDER BY 
    ai.cumulative_sales DESC NULLS LAST, 
    ai.i_product_name ASC;
