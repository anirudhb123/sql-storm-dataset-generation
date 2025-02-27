
WITH RankedSales AS (
    SELECT 
        ws.web_site_id,
        ws_net_paid_inc_tax,
        RANK() OVER (PARTITION BY ws.web_site_id ORDER BY ws_net_paid_inc_tax DESC) as rank_sales
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    WHERE
        c.c_birth_year BETWEEN 1970 AND 1990
        AND ws_net_paid_inc_tax IS NOT NULL
),
TotalSales AS (
    SELECT 
        ws.web_site_id,
        SUM(ws_net_paid_inc_tax) AS total_sales
    FROM 
        web_sales ws
    WHERE 
        ws.ws_ship_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        ws.web_site_id
),
SalesSummary AS (
    SELECT 
        R.web_site_id,
        R.ws_net_paid_inc_tax,
        T.total_sales,
        (R.ws_net_paid_inc_tax / NULLIF(T.total_sales, 0)) AS sales_ratio
    FROM
        RankedSales R 
    JOIN 
        TotalSales T ON R.web_site_id = T.web_site_id
    WHERE 
        R.rank_sales <= 3
),
FilteredSummary AS (
    SELECT 
        *,
        CASE 
            WHEN sales_ratio > 0.5 THEN 'High'
            WHEN sales_ratio IS NULL THEN 'No Sales'
            ELSE 'Low'
        END AS sales_classification
    FROM 
        SalesSummary
),
AggSales AS (
    SELECT 
        sales_classification,
        COUNT(*) AS count_sales_class
    FROM 
        FilteredSummary
    GROUP BY 
        sales_classification
)
SELECT 
    F.web_site_id,
    F.ws_net_paid_inc_tax,
    F.total_sales,
    F.sales_classification,
    A.count_sales_class
FROM 
    FilteredSummary F
LEFT JOIN 
    AggSales A ON F.sales_classification = A.sales_classification
WHERE 
    F.total_sales IS NOT NULL 
    AND F.sales_classification IS NOT NULL
ORDER BY 
    F.total_sales DESC, F.web_site_id;
