
WITH ItemSales AS (
    SELECT 
        i.i_item_sk,
        i.i_item_id,
        COALESCE(SUM(ws.ws_quantity), 0) AS total_web_sales,
        COALESCE(SUM(cs.cs_quantity), 0) AS total_catalog_sales,
        COALESCE(SUM(ss.ss_quantity), 0) AS total_store_sales
    FROM 
        item i
    LEFT JOIN 
        web_sales ws ON i.i_item_sk = ws.ws_item_sk
    LEFT JOIN 
        catalog_sales cs ON i.i_item_sk = cs.cs_item_sk
    LEFT JOIN 
        store_sales ss ON i.i_item_sk = ss.ss_item_sk
    GROUP BY 
        i.i_item_sk, i.i_item_id
),
IncomeDemographics AS (
    SELECT 
        hd.hd_demo_sk,
        SUM(CASE WHEN hd.hd_income_band_sk IS NOT NULL THEN 1 ELSE 0 END) AS income_segment_count
    FROM 
        household_demographics hd
    GROUP BY 
        hd.hd_demo_sk
),
TopItems AS (
    SELECT 
        isales.i_item_id,
        (isales.total_web_sales + isales.total_catalog_sales + isales.total_store_sales) AS total_sales,
        RANK() OVER (ORDER BY (isales.total_web_sales + isales.total_catalog_sales + isales.total_store_sales) DESC) as sales_rank
    FROM 
        ItemSales isales
    WHERE 
        (isales.total_web_sales + isales.total_catalog_sales + isales.total_store_sales) > 0
)
SELECT 
    ti.i_item_id,
    ti.total_sales,
    id.income_segment_count
FROM 
    TopItems ti
LEFT JOIN 
    IncomeDemographics id ON id.hd_demo_sk = (SELECT MIN(hd.hd_demo_sk) FROM household_demographics hd)  -- Assume a correlated subquery for demonstration purpose
WHERE 
    ti.sales_rank <= 10
ORDER BY 
    ti.total_sales DESC;
