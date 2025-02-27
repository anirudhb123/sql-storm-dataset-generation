
WITH RankedSales AS (
    SELECT 
        ws_item_sk,
        SUM(ws_sales_price * ws_quantity) AS total_sales,
        RANK() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_sales_price * ws_quantity) DESC) AS sales_rank
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk
),
TopItems AS (
    SELECT 
        rs.ws_item_sk,
        i.i_item_desc,
        rs.total_sales,
        CASE 
            WHEN EXISTS (
                SELECT 1 
                FROM catalog_sales cs 
                WHERE cs.cs_item_sk = rs.ws_item_sk AND cs.cs_sold_date_sk > 20230101
            ) THEN 'Catalog Sales'
            ELSE 'Web Sales'
        END AS sales_source
    FROM 
        RankedSales rs
    JOIN 
        item i ON rs.ws_item_sk = i.i_item_sk
    WHERE 
        rs.sales_rank <= 10
),
SalesDetails AS (
    SELECT 
        t.d_date,
        ti.ws_item_sk,
        ti.i_item_desc,
        ti.total_sales,
        ti.sales_source,
        COALESCE(WEB.ws_ext_discount_amt, 0) AS web_discount,
        COALESCE(CAT.cs_ext_discount_amt, 0) AS catalog_discount
    FROM 
        TopItems ti
    LEFT JOIN 
        (SELECT ws_item_sk, SUM(ws_ext_discount_amt) AS ws_ext_discount_amt 
         FROM web_sales 
         WHERE ws_sold_date_sk BETWEEN 20230101 AND 20231231 
         GROUP BY ws_item_sk) WEB ON ti.ws_item_sk = WEB.ws_item_sk
    LEFT JOIN 
        (SELECT cs_item_sk, SUM(cs_ext_discount_amt) AS cs_ext_discount_amt 
         FROM catalog_sales 
         WHERE cs_sold_date_sk BETWEEN 20230101 AND 20231231 
         GROUP BY cs_item_sk) CAT ON ti.ws_item_sk = CAT.cs_item_sk
    JOIN 
        date_dim t ON t.d_date_sk = CURRENT_DATE
)
SELECT 
    sd.d_date,
    sd.i_item_desc,
    sd.total_sales,
    sd.sales_source,
    sd.web_discount,
    sd.catalog_discount,
    CASE 
        WHEN sd.web_discount > sd.catalog_discount THEN 'Web'
        ELSE 'Catalog'
    END AS higher_discount
FROM 
    SalesDetails sd
WHERE 
    sd.total_sales IS NOT NULL
ORDER BY 
    sd.total_sales DESC;
