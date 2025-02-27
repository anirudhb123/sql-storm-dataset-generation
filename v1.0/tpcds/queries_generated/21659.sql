
WITH RankedSales AS (
    SELECT 
        ws_item_sk,
        SUM(ws_sales_price) AS total_sales,
        RANK() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_sales_price) DESC) AS sales_rank
    FROM 
        web_sales 
    GROUP BY 
        ws_item_sk
),
HighSales AS (
    SELECT 
        item.i_item_sk, 
        item.i_item_id, 
        item.i_product_name,
        COALESCE(RankedSales.total_sales, 0) AS total_sales
    FROM 
        item
    LEFT JOIN 
        RankedSales ON item.i_item_sk = RankedSales.ws_item_sk
    WHERE 
        item.i_current_price IS NOT NULL
        AND (item.i_item_desc LIKE '%gadget%' OR item.i_product_name LIKE '%gadget%')
        AND NOT EXISTS (
            SELECT 1 
            FROM store_sales 
            WHERE ss_item_sk = item.i_item_sk 
              AND ss_sold_date_sk > 20231101
        )
),
CustomerWindow AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_ext_sales_price) OVER (PARTITION BY c.c_customer_sk ORDER BY ws.ws_sold_date_sk ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_sales,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS rank
    FROM 
        customer AS c
    JOIN 
        web_sales AS ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        c.c_birth_year IS NOT NULL
        AND (c.c_birth_month BETWEEN 1 AND 6 OR c.c_birth_month IS NULL)
)
SELECT 
    cs.c_customer_sk,
    cs.c_first_name,
    cs.c_last_name,
    hs.i_item_id,
    hs.total_sales,
    cw.cumulative_sales,
    cw.rank
FROM 
    HighSales AS hs
JOIN 
    CustomerWindow AS cw ON hs.total_sales > cw.cumulative_sales
JOIN 
    customer AS cs ON cs.c_customer_sk = cw.c_customer_sk
WHERE 
    hs.total_sales IS NOT NULL
    AND cw.rank <= 5
ORDER BY 
    hs.total_sales DESC, 
    cw.cumulative_sales ASC
OFFSET 10 ROWS FETCH NEXT 10 ROWS ONLY;
