
WITH RecursiveSales AS (
    SELECT 
        ws_item_sk,
        ws_order_number,
        ws_sales_price,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_order_number DESC) AS rn
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2023)
),
SalesComparison AS (
    SELECT 
        item.i_item_id,
        item.i_item_desc,
        COALESCE(wr_total, 0) AS web_sales_total,
        COALESCE(cs_total, 0) AS catalog_sales_total,
        COALESCE(ss_total, 0) AS store_sales_total,
        (COALESCE(wr_total, 0) + COALESCE(cs_total, 0) + COALESCE(ss_total, 0)) AS total_sales
    FROM 
        item
    LEFT JOIN (
        SELECT 
            ws_item_sk,
            SUM(ws_net_paid_inc_tax) AS wr_total
        FROM 
            web_returns
        GROUP BY 
            ws_item_sk
    ) AS web_sales_total ON item.i_item_sk = web_sales_total.ws_item_sk
    LEFT JOIN (
        SELECT 
            cs_item_sk,
            SUM(cs_net_paid_inc_tax) AS cs_total
        FROM 
            catalog_sales
        GROUP BY 
            cs_item_sk
    ) AS catalog_sales_total ON item.i_item_sk = catalog_sales_total.cs_item_sk
    LEFT JOIN (
        SELECT 
            ss_item_sk,
            SUM(ss_net_paid_inc_tax) AS ss_total
        FROM 
            store_sales
        GROUP BY 
            ss_item_sk
    ) AS store_sales_total ON item.i_item_sk = store_sales_total.ss_item_sk
),
TopSellingItems AS (
    SELECT 
        i_item_id,
        i_item_desc,
        ROW_NUMBER() OVER (ORDER BY total_sales DESC) AS rank
    FROM 
        SalesComparison
)
SELECT 
    tsi.i_item_id,
    tsi.i_item_desc,
    s.web_sales_total,
    s.catalog_sales_total,
    s.store_sales_total,
    s.total_sales
FROM 
    TopSellingItems tsi
JOIN 
    SalesComparison s ON tsi.i_item_id = s.i_item_id
WHERE 
    tsi.rank <= 10
ORDER BY 
    s.total_sales DESC;
