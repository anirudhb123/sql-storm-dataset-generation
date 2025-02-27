
WITH RankedSales AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_sales_price) DESC) AS rank
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023) AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        ws_item_sk
), 
TopSales AS (
    SELECT 
        r.ws_item_sk,
        r.total_quantity,
        r.total_sales
    FROM 
        RankedSales r
    WHERE 
        r.rank = 1
), 
StoreSales AS (
    SELECT 
        ss_item_sk,
        SUM(ss_quantity) AS store_total_quantity,
        SUM(ss_sales_price) AS store_total_sales
    FROM 
        store_sales
    WHERE 
        ss_sold_date_sk = (SELECT MAX(ss_sold_date_sk) FROM store_sales)
    GROUP BY 
        ss_item_sk
), 
CombinedSales AS (
    SELECT 
        t.ws_item_sk,
        t.total_quantity + COALESCE(s.store_total_quantity, 0) AS combined_quantity,
        t.total_sales + COALESCE(s.store_total_sales, 0) AS combined_sales
    FROM 
        TopSales t
    LEFT JOIN 
        StoreSales s ON t.ws_item_sk = s.ss_item_sk
), 
SalesAnalysis AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        cs.combined_quantity,
        cs.combined_sales,
        JSON_OBJECT(
            'customer_id' VALUE c.c_customer_id, 
            'first_name' VALUE c.c_first_name, 
            'last_name' VALUE c.c_last_name,
            'combined_quantity' VALUE cs.combined_quantity,
            'combined_sales' VALUE cs.combined_sales
        ) AS customer_data
    FROM 
        customer c
    INNER JOIN 
        CombinedSales cs ON c.c_customer_sk = (SELECT TOP 1 ws_bill_customer_sk FROM web_sales w WHERE w.ws_item_sk = cs.ws_item_sk ORDER BY w.ws_quantity DESC)
    WHERE 
        c.c_birth_year IS NOT NULL AND 
        c.c_current_addr_sk IS NOT NULL
)
SELECT 
    s.c_customer_id,
    s.combined_sales,
    CASE 
        WHEN s.combined_sales IS NULL THEN 'No Sales'
        WHEN s.combined_sales > 10000 THEN 'High Sales'
        ELSE 'Regular Sales'
    END AS sales_category,
    (SELECT COUNT(DISTINCT ws_order_number) FROM web_sales WHERE ws_bill_customer_sk = s.c_customer_id) AS order_count
FROM 
    SalesAnalysis s
WHERE 
    EXISTS (
        SELECT 1 
        FROM customer_demographics cd 
        WHERE cd.cd_demo_sk = c.c_current_cdemo_sk AND cd.cd_gender = 'M'
        HAVING COUNT(cd.cd_demo_sk) > 2
    )
AND 
    (s.combined_sales > 500 OR s.combined_quantity IS NULL)
ORDER BY 
    s.combined_sales DESC
LIMIT 100 OFFSET 10;
