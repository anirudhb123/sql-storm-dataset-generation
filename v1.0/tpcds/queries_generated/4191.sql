
WITH SalesSummary AS (
    SELECT
        CASE 
            WHEN ws_sales.total_sales IS NULL THEN 0
            ELSE ws_sales.total_sales
        END AS total_sales,
        CASE 
            WHEN w.warehouse_name IS NULL THEN 'Unknown'
            ELSE w.warehouse_name
        END AS warehouse_name,
        cd.gender,
        DENSE_RANK() OVER (PARTITION BY cd.gender ORDER BY ws_sales.total_sales DESC) AS gender_rank
    FROM (
        SELECT
            ws.web_site_sk,
            SUM(ws.ws_net_paid) AS total_sales
        FROM 
            web_sales ws
        JOIN 
            customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
        GROUP BY 
            ws.web_site_sk
    ) AS ws_sales
    LEFT OUTER JOIN 
        web_site w ON ws_sales.web_site_sk = w.web_site_sk
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
HighestSales AS (
    SELECT 
        warehouse_name, total_sales
    FROM 
        SalesSummary
    WHERE 
        gender_rank = 1
    ORDER BY 
        total_sales DESC
    LIMIT 10
)

SELECT
    COALESCE(hs.warehouse_name, 'No Warehouse Data') AS warehouse,
    hs.total_sales AS sales_value,
    NVL((SELECT AVG(total_sales) FROM SalesSummary), 0) AS avg_sales,
    CASE
        WHEN hs.total_sales > 10000 THEN 'High'
        WHEN hs.total_sales > 5000 THEN 'Medium'
        ELSE 'Low'
    END AS sales_category
FROM 
    HighestSales hs
ORDER BY 
    hs.total_sales DESC
UNION ALL 
SELECT 
    'Total Sales' AS warehouse,
    SUM(total_sales) AS sales_value,
    NULL AS avg_sales,
    NULL AS sales_category
FROM 
    SalesSummary;
