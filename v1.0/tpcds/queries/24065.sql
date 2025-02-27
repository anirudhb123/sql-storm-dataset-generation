
WITH CustomerSales AS (
    SELECT 
        c.c_customer_id,
        SUM(ss.ss_net_paid) AS total_sales,
        COUNT(DISTINCT ss.ss_ticket_number) AS purchase_count,
        MAX(ss.ss_net_paid) AS max_purchase,
        AVG(ss.ss_net_paid) AS avg_purchase
    FROM customer c
    JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY c.c_customer_id
),
SalesDetails AS (
    SELECT 
        cs.c_customer_id,
        cs.total_sales,
        cs.purchase_count,
        cs.max_purchase,
        cs.avg_purchase,
        ROW_NUMBER() OVER (PARTITION BY CASE WHEN cs.total_sales > 1000 THEN 'High' ELSE 'Low' END ORDER BY cs.total_sales DESC) AS sales_rank
    FROM CustomerSales cs
),
FilteredSales AS (
    SELECT 
        sd.c_customer_id,
        sd.total_sales,
        sd.purchase_count,
        sd.max_purchase,
        sd.avg_purchase,
        sd.sales_rank
    FROM SalesDetails sd
    WHERE sd.purchase_count > 5 AND sd.avg_purchase IS NOT NULL
)
SELECT 
    fs.c_customer_id,
    fs.total_sales,
    fs.purchase_count,
    fs.max_purchase,
    fs.avg_purchase,
    COALESCE(ib.ib_income_band_sk, -1) AS income_band,
    CASE 
        WHEN fs.sales_rank = 1 THEN 'Top Performer'
        WHEN fs.sales_rank BETWEEN 2 AND 5 THEN 'Considered'
        ELSE 'Low Performer'
    END AS performance_category
FROM FilteredSales fs
LEFT JOIN household_demographics hd ON hd.hd_demo_sk = (
    SELECT cd.cd_demo_sk 
    FROM customer_demographics cd 
    WHERE cd.cd_demo_sk = (
        SELECT c.c_current_cdemo_sk 
        FROM customer c 
        WHERE c.c_customer_id = fs.c_customer_id
    )
) 
LEFT JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
WHERE fs.total_sales IS NOT NULL
    AND (hd.hd_dep_count IS NULL OR hd.hd_dep_count > 2)
UNION ALL
SELECT 
    'Total' AS c_customer_id,
    SUM(total_sales),
    NULL AS purchase_count,
    NULL AS max_purchase,
    NULL AS avg_purchase,
    NULL AS income_band,
    'Overall Summary' AS performance_category
FROM FilteredSales;
