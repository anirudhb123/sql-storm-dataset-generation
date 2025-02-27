
WITH RECURSIVE sales_data AS (
    SELECT 
        cs_item_sk,
        SUM(cs_sales_price) AS total_sales,
        COUNT(cs_order_number) AS order_count,
        CURRENT_DATE AS calc_date
    FROM catalog_sales
    GROUP BY cs_item_sk
    UNION ALL
    SELECT 
        cs.cs_item_sk,
        sd.total_sales + COALESCE(SUM(cs.cs_sales_price), 0) AS total_sales,
        sd.order_count + COUNT(cs.cs_order_number) AS order_count,
        CURRENT_DATE - INTERVAL '1 DAY' AS calc_date
    FROM sales_data sd
    LEFT JOIN catalog_sales cs ON sd.cs_item_sk = cs.cs_item_sk AND cs.cs_sold_date_sk < sd.calc_date
    WHERE sd.calc_date > (CURRENT_DATE - INTERVAL '30 DAY') 
    GROUP BY cs.cs_item_sk, sd.total_sales, sd.order_count
),
item_avg_sales AS (
    SELECT 
        i.i_item_id,
        AVG(sd.total_sales) AS avg_sales,
        MAX(sd.order_count) AS max_orders
    FROM sales_data sd
    JOIN item i ON sd.cs_item_sk = i.i_item_sk
    GROUP BY i.i_item_id
),
high_sales_items AS (
    SELECT 
        i.i_item_id,
        i.i_product_name,
        COALESCE(ib.ib_lower_bound, 0) AS lower_income_band,
        COALESCE(ib.ib_upper_bound, 1000000) AS upper_income_band
    FROM item i
    LEFT JOIN income_band ib ON i.i_item_sk % 100 = ib.ib_income_band_sk
)
SELECT 
    hsi.i_item_id,
    hsi.i_product_name,
    hs.avg_sales,
    hs.max_orders,
    CASE 
        WHEN hsi.lower_income_band < 50000 AND hsi.upper_income_band > 0 THEN 'Low Income'
        WHEN hsi.lower_income_band BETWEEN 50000 AND 100000 THEN 'Middle Income'
        ELSE 'High Income'
    END AS income_category
FROM high_sales_items hsi
JOIN item_avg_sales hs ON hsi.i_item_id = hs.i_item_id
WHERE (hs.avg_sales > 500 AND hs.max_orders > 5)
ORDER BY income_category, hs.avg_sales DESC
LIMIT 10;
