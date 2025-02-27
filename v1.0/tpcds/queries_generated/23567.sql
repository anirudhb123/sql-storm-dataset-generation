
WITH demographic_summary AS (
    SELECT 
        cd_gender,
        SUM(cd_dep_count) AS total_dependencies,
        AVG(cd_purchase_estimate) AS avg_purchase_estimate,
        COUNT(*) AS customer_count
    FROM customer_demographics
    WHERE cd_credit_rating IS NOT NULL
    GROUP BY cd_gender
),
item_summary AS (
    SELECT 
        i_brand,
        AVG(i_current_price) AS avg_price,
        COUNT(i_item_sk) AS item_count,
        SUM(CASE WHEN i_current_price IS NULL THEN 1 ELSE 0 END) AS null_price_count
    FROM item
    GROUP BY i_brand
),
store_summary AS (
    SELECT 
        s_city,
        COUNT(s_store_sk) AS store_count,
        SUM(s_floor_space) AS total_floor_space
    FROM store
    GROUP BY s_city
)

SELECT 
    ds.cd_gender,
    ds.total_dependencies,
    ds.avg_purchase_estimate,
    isr.avg_price,
    isr.item_count,
    ss.store_count,
    ss.total_floor_space
FROM demographic_summary ds
LEFT JOIN item_summary isr ON ds.total_dependencies > 10
JOIN store_summary ss ON ss.store_count > 0
WHERE ds.customer_count > 5
AND (ds.cd_gender = 'M' OR ds.cd_gender = 'F')
AND ss.total_floor_space IS NOT NULL
ORDER BY ds.total_dependencies DESC, isr.avg_price ASC
LIMIT 10
UNION
SELECT 
    'Aggregate' AS cd_gender,
    SUM(total_dependencies) AS total_dependencies,
    AVG(avg_purchase_estimate) AS avg_purchase_estimate,
    AVG(avg_price) AS avg_price,
    SUM(item_count) AS item_count,
    SUM(store_count) AS store_count,
    SUM(total_floor_space) AS total_floor_space
FROM (
    SELECT 
        ds.total_dependencies,
        ds.avg_purchase_estimate,
        isr.avg_price,
        isr.item_count,
        ss.store_count,
        ss.total_floor_space
    FROM demographic_summary ds
    LEFT JOIN item_summary isr ON ds.total_dependencies > 10
    JOIN store_summary ss ON ss.store_count > 0
) AS combined_data
WHERE total_dependencies IS NOT NULL;
