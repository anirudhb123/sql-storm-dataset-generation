
WITH RankedSales AS (
    SELECT 
        ws.web_site_sk,
        ws.ws_sold_date_sk,
        SUM(ws.ws_sales_price) AS total_sales,
        RANK() OVER (PARTITION BY ws.web_site_sk ORDER BY SUM(ws.ws_sales_price) DESC) AS sales_rank
    FROM 
        web_sales ws
    INNER JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        c.c_birth_year BETWEEN 1970 AND 1990
        AND cd.cd_marital_status IS NOT NULL
        AND (cd.cd_gender = 'M' OR cd.cd_gender = 'F')
    GROUP BY 
        ws.web_site_sk, ws.ws_sold_date_sk
),
SalesSummary AS (
    SELECT 
        d.d_year,
        r.sales_rank,
        AVG(r.total_sales) AS avg_sales,
        COUNT(DISTINCT r.web_site_sk) AS active_sites
    FROM 
        RankedSales r
    JOIN 
        date_dim d ON r.ws_sold_date_sk = d.d_date_sk
    GROUP BY 
        d.d_year, r.sales_rank
),
SalesCounts AS (
    SELECT 
        d.d_year,
        COUNT(DISTINCT CASE WHEN r.sales_rank = 1 THEN r.web_site_sk END) AS top_sites,
        COUNT(DISTINCT CASE WHEN r.sales_rank > 1 AND r.sales_rank <= 5 THEN r.web_site_sk END) AS mid_sites,
        COUNT(DISTINCT CASE WHEN r.sales_rank > 5 THEN r.web_site_sk END) AS low_sites
    FROM 
        RankedSales r
    JOIN 
        date_dim d ON r.ws_sold_date_sk = d.d_date_sk
    GROUP BY 
        d.d_year
)

SELECT 
    d.d_year,
    COALESCE(SUM(ss.avg_sales), 0) AS average_sales,
    COALESCE(MAX(sc.top_sites), 0) AS top_site_count,
    COALESCE(MIN(sc.mid_sites), 0) AS mid_site_count,
    COALESCE(MAX(sc.low_sites), 0) AS low_site_count
FROM 
    date_dim d
LEFT JOIN 
    SalesSummary ss ON d.d_year = ss.d_year
LEFT JOIN 
    SalesCounts sc ON d.d_year = sc.d_year
WHERE 
    d.d_year BETWEEN 2015 AND 2023
GROUP BY 
    d.d_year
ORDER BY 
    d.d_year DESC;
