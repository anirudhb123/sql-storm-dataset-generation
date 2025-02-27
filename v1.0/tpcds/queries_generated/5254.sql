
WITH aggregated_sales AS (
    SELECT
        d.d_year,
        SUM(ws.ws_sales_price) AS total_web_sales,
        SUM(cs.cs_sales_price) AS total_catalog_sales,
        SUM(ss.ss_sales_price) AS total_store_sales
    FROM
        date_dim d
    LEFT JOIN web_sales ws ON d.d_date_sk = ws.ws_sold_date_sk
    LEFT JOIN catalog_sales cs ON d.d_date_sk = cs.cs_sold_date_sk
    LEFT JOIN store_sales ss ON d.d_date_sk = ss.ss_sold_date_sk
    GROUP BY
        d.d_year
),
market_analysis AS (
    SELECT 
        cd.cd_gender, 
        cd.cd_marital_status,
        SUM(total_web_sales) AS total_web_sales_by_gender,
        SUM(total_catalog_sales) AS total_catalog_sales_by_gender,
        SUM(total_store_sales) AS total_store_sales_by_gender
    FROM 
        aggregated_sales a
    JOIN customer Demographics cd ON cd.cd_demo_sk = a.total_web_sales
    GROUP BY 
        cd.cd_gender,
        cd.cd_marital_status
)
SELECT 
    ma.cd_gender,
    ma.cd_marital_status,
    ma.total_web_sales_by_gender,
    ma.total_catalog_sales_by_gender,
    ma.total_store_sales_by_gender
FROM 
    market_analysis ma
WHERE 
    ma.total_web_sales_by_gender > (SELECT AVG(total_web_sales_by_gender) FROM market_analysis)
ORDER BY 
    ma.total_web_sales_by_gender DESC
LIMIT 10;
