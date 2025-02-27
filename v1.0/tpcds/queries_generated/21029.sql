
WITH RankedSales AS (
    SELECT 
        ws.web_site_id,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        ROW_NUMBER() OVER(PARTITION BY ws.web_site_id ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS rank
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2023
    GROUP BY 
        ws.web_site_id
),
FilteredSales AS (
    SELECT 
        r.web_site_id,
        r.total_quantity,
        r.total_sales,
        ga.c_demo_sk,
        ga.cc_class,
        ga.cc_mkt_class,
        ga.cc_tax_percentage,
        ga.cc_manager
    FROM 
        RankedSales r
    LEFT JOIN 
        call_center ga ON r.total_sales > (SELECT AVG(total_sales) FROM RankedSales)
    WHERE 
        r.rank <= 5 OR (ga.cc_tax_percentage IS NOT NULL AND ga.cc_manager LIKE 'M%')
),
FinalSales AS (
    SELECT 
        fs.web_site_id,
        fs.total_quantity,
        fs.total_sales,
        SUM(COALESCE(ga.cc_tax_percentage, 0)) OVER(PARTITION BY fs.web_site_id) AS total_tax_percentage
    FROM 
        FilteredSales fs
    LEFT JOIN 
        income_band ib ON fs.total_sales BETWEEN ib.ib_lower_bound AND ib.ib_upper_bound
)
SELECT 
    fs.web_site_id,
    fs.total_quantity,
    fs.total_sales,
    CASE 
        WHEN fs.total_tax_percentage IS NULL THEN 'No Tax'
        ELSE CONCAT('Tax Rate: ', fs.total_tax_percentage)
    END AS tax_info,
    (SELECT COUNT(*) FROM customer c 
     WHERE c.c_current_cdemo_sk IN (SELECT DISTINCT fs.c_demo_sk FROM FilteredSales fs)) AS unique_customers
FROM 
    FinalSales fs
WHERE 
    fs.total_quantity > (SELECT AVG(total_quantity) FROM FinalSales)
ORDER BY 
    fs.total_sales DESC
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY;
