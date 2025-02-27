
WITH RankedSales AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        ws_sales_price,
        RANK() OVER (PARTITION BY ws_item_sk ORDER BY ws_sales_price DESC) AS rank_by_price
    FROM 
        web_sales
    WHERE 
        ws_sales_price IS NOT NULL
),
SalesSum AS (
    SELECT 
        rr.ws_item_sk,
        SUM(rr.ws_sales_price) AS total_sales,
        COUNT(rr.ws_sales_price) AS sales_count
    FROM 
        RankedSales rr
    WHERE 
        rank_by_price <= 5
    GROUP BY 
        rr.ws_item_sk
),
TopSales AS (
    SELECT 
        ss.s_item_sk,
        ss.ss_sales_price,
        s.total_sales,
        s.sales_count,
        CASE 
            WHEN s.sales_count > 0 THEN s.total_sales / s.sales_count 
            ELSE NULL 
        END AS avg_sales_price
    FROM 
        store_sales ss
    JOIN 
        SalesSum s ON ss.ss_item_sk = s.ws_item_sk
    WHERE 
        ss.s_sales_price > (SELECT AVG(ws_sales_price) FROM web_sales WHERE ws_sales_price IS NOT NULL)
)
SELECT 
    t.c_first_name,
    t.c_last_name,
    COALESCE(sp.total_sales, 0) AS total_sales_at_store,
    COALESCE(sp.sales_count, 0) AS total_sells,
    AVG(sp.avg_sales_price) OVER (PARTITION BY t.c_gender) AS avg_price_by_gender
FROM 
    customer t
LEFT JOIN 
    (SELECT 
         ss.ss_item_sk,
         SUM(ss.ss_sales_price) AS total_sales,
         COUNT(ss.ss_sales_price) AS sales_count
     FROM 
         store_sales ss
     WHERE 
         ss.ss_sold_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023) 
         AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
     GROUP BY 
         ss.ss_item_sk
    ) sp ON t.c_customer_sk = sp.ss_item_sk
WHERE 
    (t.c_birth_month IS NULL OR t.c_birth_month < 6) 
    AND (EXISTS (SELECT 1 FROM customer_demographics cd WHERE cd.cd_demo_sk = t.c_current_cdemo_sk AND cd.cd_gender = 'M')
         OR NOT EXISTS (SELECT 1 FROM customer_demographics cd WHERE cd.cd_demo_sk = t.c_current_cdemo_sk AND cd.cd_gender = 'F'))
ORDER BY 
    total_sales_at_store DESC NULLS LAST, 
    avg_price_by_gender ASC;
