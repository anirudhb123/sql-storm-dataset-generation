
WITH RecursiveSales AS (
    SELECT 
        ws_item_sk,
        ws_sales_price,
        ws_quantity,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_sold_date_sk DESC) AS rn
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk > 20220101
), ItemSales AS (
    SELECT 
        i.i_item_sk,
        i.i_item_desc,
        COALESCE(SUM(rs.ws_sales_price * rs.ws_quantity), 0) AS total_sales,
        COUNT(DISTINCT CASE WHEN rs.rn = 1 THEN ws_web_page_sk END) AS unique_web_page_views
    FROM 
        item i
    LEFT JOIN 
        RecursiveSales rs ON i.i_item_sk = rs.ws_item_sk
    GROUP BY 
        i.i_item_sk, i.i_item_desc
), Demographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        hd.hd_income_band_sk,
        COUNT(DISTINCT c.c_customer_sk) AS customer_count
    FROM 
        customer_demographics cd
    JOIN 
        household_demographics hd ON cd.cd_demo_sk = hd.hd_demo_sk
    JOIN 
        customer c ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        cd.cd_gender IS NOT NULL
    GROUP BY 
        cd.cd_demo_sk, cd.cd_gender, hd.hd_income_band_sk
)
SELECT 
    i.i_item_sk,
    i.i_item_desc,
    i.total_sales,
    d.cd_gender,
    d.hd_income_band_sk,
    d.customer_count,
    ROW_NUMBER() OVER (PARTITION BY d.hd_income_band_sk ORDER BY i.total_sales DESC) AS rank
FROM 
    ItemSales i
JOIN 
    Demographics d ON i.total_sales > 1000 OR d.customer_count IS NULL
ORDER BY 
    d.hd_income_band_sk, i.total_sales DESC
LIMIT 100
OFFSET (SELECT COUNT(DISTINCT cd_demo_sk) FROM customer_demographics WHERE cd_gender <> 'F' AND hd_income_band_sk BETWEEN 200000 AND 400000)
