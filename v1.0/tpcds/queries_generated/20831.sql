
WITH RankedSales AS (
    SELECT 
        s_store_sk, 
        ss_item_sk, 
        SUM(ss_quantity) AS total_quantity,
        ROW_NUMBER() OVER (PARTITION BY ss_item_sk ORDER BY SUM(ss_quantity) DESC) AS rank
    FROM store_sales
    GROUP BY s_store_sk, ss_item_sk
),
HighVolumeStores AS (
    SELECT 
        s_store_sk, 
        SUM(total_quantity) AS store_total
    FROM RankedSales
    WHERE rank = 1
    GROUP BY s_store_sk
),
StoreDetails AS (
    SELECT 
        st.s_store_id, 
        st.s_store_name, 
        s.total_quantity,
        CASE
            WHEN s.total_quantity IS NULL THEN 'No Sales'
            ELSE 'Sales Recorded'
        END AS sales_status
    FROM store st
    LEFT JOIN HighVolumeStores s ON st.s_store_sk = s.s_store_sk
),
Demographics AS (
    SELECT 
        cd_gender, 
        COUNT(*) AS customer_count
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE cd_cd.marital_status = 'M' OR cd.gender = 'F'
    GROUP BY cd_gender
),
FinalResults AS (
    SELECT 
        sd.s_store_id, 
        sd.s_store_name, 
        COALESCE(d.customer_count, 0) AS customer_count, 
        sd.sales_status,
        sd.total_quantity AS total_store_sales,
        CASE 
            WHEN d.customer_count > 100 THEN 'High Customer Engagement'
            WHEN d.customer_count BETWEEN 50 AND 100 THEN 'Moderate Engagement'
            ELSE 'Low Engagement'
        END AS engagement_level
    FROM StoreDetails sd
    LEFT JOIN Demographics d ON sd.s_store_id = d.cd_gender
)
SELECT 
    f.s_store_id, 
    f.s_store_name, 
    f.customer_count, 
    f.sales_status, 
    f.total_store_sales, 
    f.engagement_level
FROM FinalResults f
WHERE f.total_store_sales > COALESCE((SELECT AVG(total_quantity) FROM RankedSales), 1)
ORDER BY f.total_store_sales DESC
LIMIT 10;
