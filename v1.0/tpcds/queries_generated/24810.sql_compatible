
WITH RankedSales AS (
    SELECT 
        c.c_customer_id,
        COALESCE(SUM(ws.ws_sales_price), 0) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_id ORDER BY COALESCE(SUM(ws.ws_sales_price), 0) DESC) AS rank_sales
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year BETWEEN 2019 AND 2023
    GROUP BY 
        c.c_customer_id
), TotalSales AS (
    SELECT 
        SUM(total_sales) AS overall_sales
    FROM 
        RankedSales
)
SELECT 
    r.c_customer_id,
    r.total_sales,
    r.rank_sales,
    CASE 
        WHEN r.rank_sales = 1 THEN 'Top Customer'
        WHEN r.total_sales > (SELECT overall_sales / 10 FROM TotalSales) THEN 'Above Average'
        ELSE 'Below Average'
    END AS sales_category,
    NULLIF(r.total_sales / NULLIF((SELECT COUNT(*) FROM customer), 0), 0) AS avg_sales_per_customer
FROM 
    RankedSales r
WHERE 
    r.total_sales > (SELECT AVG(total_sales) FROM RankedSales WHERE rank_sales <= 10)
ORDER BY 
    r.total_sales DESC
OFFSET 5 ROWS FETCH NEXT 10 ROWS ONLY
UNION ALL
SELECT 
    NULL AS c_customer_id,
    SUM(ws.ws_sales_price) AS total_sales,
    NULL AS rank_sales,
    'Total Sales Across All Customers' AS sales_category,
    NULL AS avg_sales_per_customer
FROM 
    web_sales ws 
WHERE 
    ws.ws_ship_date_sk IS NOT NULL
AND 
    ws.ws_sales_price IS NOT NULL;
