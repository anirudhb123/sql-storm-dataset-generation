
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_customer_id,
        SUM(ws.ws_net_paid) AS total_web_sales,
        SUM(cs.cs_net_paid) AS total_catalog_sales,
        SUM(ss.ss_net_paid) AS total_store_sales,
        CASE 
            WHEN SUM(ws.ws_net_paid) IS NOT NULL AND SUM(cs.cs_net_paid) IS NOT NULL THEN 'Both Web and Catalog'
            WHEN SUM(ws.ws_net_paid) IS NOT NULL THEN 'Web Only'
            WHEN SUM(cs.cs_net_paid) IS NOT NULL THEN 'Catalog Only'
            ELSE 'No Sales'
        END AS sales_channel
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN 
        catalog_sales cs ON c.c_customer_sk = cs.cs_bill_customer_sk
    LEFT JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_customer_id
),
SalesRanking AS (
    SELECT 
        cs.c_customer_id,
        cs.total_web_sales,
        cs.total_catalog_sales,
        cs.total_store_sales,
        cs.sales_channel,
        RANK() OVER (ORDER BY COALESCE(cs.total_web_sales, 0) + COALESCE(cs.total_catalog_sales, 0) + COALESCE(cs.total_store_sales, 0) DESC) AS sales_rank
    FROM 
        CustomerSales cs
)
SELECT 
    sr.c_customer_id,
    sr.total_web_sales,
    sr.total_catalog_sales,
    sr.total_store_sales,
    sr.sales_channel,
    sr.sales_rank,
    COALESCE((SELECT MAX(ss_ext_sales_price) FROM store_sales WHERE ss_customer_sk = sr.c_customer_id), 0) AS max_store_sales_price,
    COALESCE((SELECT COUNT(DISTINCT sr_item_sk) FROM store_sales WHERE ss_customer_sk = sr.c_customer_id), 0) AS distinct_items_purchased
FROM 
    SalesRanking sr
WHERE 
    sr.sales_rank <= 10
ORDER BY 
    sr.sales_rank;
